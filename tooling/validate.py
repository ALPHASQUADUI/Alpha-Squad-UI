#!/usr/bin/env python3
"""Validate both Lua runtimes, manifests and the two installable addon packages."""
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]

def run(*args, **kwargs):
    return subprocess.run(args, cwd=ROOT, check=True, **kwargs)

def lua_quote(value):
    return '"' + str(value).replace('\\', '\\\\').replace('"', '\\"') + '"'

def main():
    runtimes = [os.environ.get('LUA51', 'lua5.1'), os.environ.get('LUA54', 'lua5.4')]
    root = ROOT / 'AlphaSquadUI'
    manifest = (root / 'AlphaSquadUI.txt').read_text()
    # Color markup counts toward ESO's short metadata fields. Keep a byte-safe
    # budget so branding survives before any addon Lua is loaded.
    for field in ('Title', 'Author'):
        value = re.search(r'^## ' + field + r': (.+)$', manifest, re.M).group(1)
        assert len(value.encode('utf-8')) <= 64, f'{field} exceeds the metadata budget'
    paths = [line.strip() for line in manifest.splitlines() if line.strip() and not line.startswith('##')]
    assert len(paths) == len(set(paths)) and all((root / path).is_file() for path in paths)
    version = re.search(r'^## Version: (.+)$', manifest, re.M).group(1)
    assert f'ASUI.version = "{version}"' in (root / 'Core/Core.lua').read_text()
    assert re.search(r'^## AddOnVersion: [0-9]+$', manifest, re.M)
    assert {p.relative_to(root).as_posix() for p in root.rglob('*.lua')} == set(paths)
    run('git', 'diff', '--check')
    source = list(root.rglob('*.lua')) + list((ROOT / 'companion').glob('*.lua'))
    with tempfile.TemporaryDirectory(prefix='asui-validate-') as temporary:
        folder = Path(temporary)
        companion = folder / 'AlphaSquadBuildShare.zip'
        run(sys.executable, 'tooling/build_companion.py', str(companion))
        with zipfile.ZipFile(companion) as archive:
            assert archive.testzip() is None
            archive.extractall(folder)
        full = folder / 'AlphaSquadUI.zip'
        with zipfile.ZipFile(full, 'w', zipfile.ZIP_DEFLATED) as archive:
            for path in sorted(root.rglob('*')):
                if path.is_file(): archive.write(path, path.relative_to(ROOT))
        with zipfile.ZipFile(full) as archive:
            assert archive.testzip() is None and 'AlphaSquadUI/AlphaSquadUI.txt' in archive.namelist()
        for runtime in runtimes:
            compile_code = ';'.join('assert(loadfile(' + lua_quote(p) + '))' for p in source)
            run(runtime, '-e', compile_code)
            for test in sorted((ROOT / 'tests').glob('*.lua')):
                run(runtime, str(test))
            run(runtime, 'tests/companion_package.lua', str(folder / 'AlphaSquadBuildShare'))
    print(f'Validated Alpha Squad UI {version}: both Lua runtimes, all suites, manifest and both ZIP packages.')

if __name__ == '__main__':
    main()
