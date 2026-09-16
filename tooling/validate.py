#!/usr/bin/env python3
"""Build once, validate the shipped payloads, and retain those exact archives."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

from build_companion import build as build_companion
from package_utils import collect_package, inspect_archive, sha256, version_numbers, write_archive
from security_scan import event_range

ROOT = Path(__file__).resolve().parents[1]


def run(*args, **kwargs):
    return subprocess.run(args, cwd=ROOT, check=True, **kwargs)


def lua_quote(value):
    return '"' + str(value).replace('\\', '\\\\').replace('"', '\\"') + '"'


def validate_manifest(root, name, expected_version=None):
    manifest = (root / f'{name}.txt').read_text()
    fields = {}
    for key, value in re.findall(r'^## (\w+): (.+)$', manifest, re.M):
        assert key not in fields, f'Duplicate manifest field: {key}'
        fields[key] = value
    # ESO short metadata fields count color markup and UTF-8 bytes too.
    for field in ('Title', 'Author'):
        assert len(fields[field].encode()) <= 64, f'{field} exceeds metadata budget'
    version = fields['Version']
    assert str(version_numbers(version)) == fields['AddOnVersion'], 'Version/AddOnVersion mismatch'
    assert expected_version is None or version == expected_version, 'Companion version mismatch'
    assert re.fullmatch(r'\d{6}(?: \d{6})*', fields['APIVersion']), 'Invalid ESO API version'
    paths = [line.strip() for line in manifest.splitlines() if line.strip() and not line.startswith('##')]
    assert len(paths) == len(set(paths)), 'Duplicate manifest path'
    for path in paths:
        file = root / path
        assert file.resolve().is_relative_to(root.resolve()), 'Manifest path escapes package'
        assert file.is_file(), f'Missing manifest file: {path}'
        assert file.suffix in {'.lua', '.xml'}, f'Unsupported manifest entry: {path}'
        if path.endswith('.xml'):
            ET.parse(file)
    for suffix in ('.lua', '.xml'):
        assert {p.relative_to(root).as_posix() for p in root.rglob('*' + suffix)} == {p for p in paths if p.endswith(suffix)}, 'Manifest does not cover all runtime files'
    if name == 'AlphaSquadUI':
        assert f'ASUI.version = "{version}"' in (root / 'Core/Core.lua').read_text(), 'Core version mismatch'
    return version, paths


def whitespace_check(base, head):
    ranges = [[], ['--cached']]
    if base:
        ranges.append([base, head])
    else:
        # A clean checkout still checks its latest committed patch.
        parents = run('git', 'rev-list', '--parents', '-n', '1', head, capture_output=True, text=True).stdout.split()
        if len(parents) > 1:
            ranges.append([parents[1], head])
    for diff_range in ranges:
        result = subprocess.run(['git', 'diff', '--check', *diff_range], cwd=ROOT, capture_output=True)
        assert result.returncode == 0, 'Whitespace errors in proposed changes (git diff --check)'


def clean_source(root=ROOT):
    """Do not trust status alone: ignored/assume-unchanged input may be modified."""
    def git(*arguments):
        return subprocess.run(['git', *arguments], cwd=root, check=True,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout
    if git('status', '--porcelain', '--untracked-files=all'):
        return False
    for name in filter(None, git('ls-files', '-z').decode().split('\0')):
        path = root / name
        if path.is_symlink() or not path.is_file():
            return False
        try:
            committed = git('show', 'HEAD:' + name)
        except subprocess.CalledProcessError:
            return False
        if path.read_bytes() != committed:
            return False
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-dir', type=Path, default=ROOT / 'dist')
    base, head = event_range()
    parser.add_argument('--base', default=base)
    parser.add_argument('--head', default=head)
    args = parser.parse_args()
    runtimes = [os.environ.get('LUA51', 'lua5.1'), os.environ.get('LUA54', 'lua5.4')]
    source_root = ROOT / 'AlphaSquadUI'
    version, _ = validate_manifest(source_root, 'AlphaSquadUI')
    scan_args = ['--head', args.head]
    if args.base:
        scan_args += ['--base', args.base]
    run(sys.executable, 'tooling/security_scan.py', *scan_args)
    whitespace_check(args.base, args.head)
    run(sys.executable, '-m', 'unittest', 'discover', '-s', 'tooling/tests', '-v')
    output = args.output_dir.resolve()
    assert not output.is_relative_to(source_root), 'Output must be outside the addon'
    output.mkdir(parents=True, exist_ok=True)
    full = output / f'AlphaSquadUI-{version}.zip'
    companion = output / f'AlphaSquadBuildShare-{version}.zip'
    members = collect_package(source_root, 'AlphaSquadUI', ROOT / 'LICENSE')
    write_archive(full, members)
    build_companion(companion)
    # Compile and run source regressions against the exact extracted shipped
    # files, including the transformed standalone companion implementation.
    with tempfile.TemporaryDirectory(prefix='asui-validate-') as temporary:
        folder = Path(temporary)
        shipped = []
        for archive, package in ((full, 'AlphaSquadUI'), (companion, 'AlphaSquadBuildShare')):
            payloads = inspect_archive(archive, package)
            if package == 'AlphaSquadUI':
                assert payloads == members, 'Full ZIP differs from collected sources'
            for name, data in payloads.items():
                path = folder / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(data)
            _, paths = validate_manifest(folder / package, package, version)
            shipped.extend(folder / package / path for path in paths if path.endswith('.lua'))
        # Existing suites use relative addon paths. Run them from the package
        # extraction directory and expose only the tests, never source runtime.
        (folder / 'tests').symlink_to(ROOT / 'tests', target_is_directory=True)
        for runtime in runtimes:
            run(runtime, '-e', ';'.join('assert(loadfile(' + lua_quote(p) + '))' for p in shipped))
            for test in sorted((ROOT / 'tests').glob('*.lua')):
                if test.name == 'companion_package.lua':
                    continue
                subprocess.run([runtime, str(test)], cwd=folder, check=True)
            subprocess.run([runtime, str(ROOT / 'tests/companion_package.lua'), str(folder / 'AlphaSquadBuildShare')], cwd=folder, check=True)
    commit = run('git', 'rev-parse', 'HEAD', capture_output=True, text=True).stdout.strip()
    dirty = not clean_source()
    notes = output / 'RELEASE_NOTES.md'
    notes.write_bytes((ROOT / 'releases' / f'{version}.md').read_bytes())
    provenance = {'version': version, 'addon_version': version_numbers(version), 'commit': commit,
                  'source_state': 'modified' if dirty else 'clean',
                  'archives': {p.name: sha256(p) for p in (full, companion)}}
    metadata = output / 'release.json'
    metadata.write_text(json.dumps(provenance, indent=2, sort_keys=True) + '\n')
    (output / 'SHA256SUMS').write_text(''.join(f'{sha256(path)}  {path.name}\n' for path in (full, companion, metadata, notes)))
    print(f'Validated Alpha Squad UI {version}: both Lua runtimes, all suites, extracted manifests and both ZIP packages.\nArtifacts: {output}')


if __name__ == '__main__':
    main()
