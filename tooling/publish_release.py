#!/usr/bin/env python3
"""Publish an explicitly authorized version from exact validated CI artifacts.

Only the release job receives contents:write. No PR event calls this publisher.
A published release is immutable here; interrupted drafts can safely resume.
"""
import argparse
import json
import os
from pathlib import Path
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

from package_utils import inspect_archive, sha256, version_numbers

ROOT = Path(__file__).resolve().parents[1]


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, response, code, message, headers, new_url):
        raise RuntimeError('Unexpected redirect; authorization was not forwarded')


def publication_request(policy, environment):
    """Fail closed before requesting credentials or writing any remote state."""
    if (policy.get('publish') is not True
            or policy.get('source_branch') != 'main'
            or environment.get('GITHUB_REPOSITORY') != policy.get('repository')
            or environment.get('GITHUB_REF') != 'refs/heads/main'
            or environment.get('GITHUB_EVENT_NAME') != 'workflow_dispatch'
            or environment.get('ASUI_RELEASE_REQUESTED') != 'true'
            or environment.get('ASUI_RELEASE_VERSION') != policy.get('version')):
        raise ValueError('Publication is not authorized for this repository/event/ref/version')
    for gate in ('environment_review_configured', 'protocol_ids_reserved',
                 'protocol_coexistence_validated', 'native_acceptance_complete'):
        if policy.get(gate) is not True:
            raise ValueError('Release prerequisite is incomplete: ' + gate)
    if policy.get('release_environment') != 'release':
        raise ValueError('Publication requires the reviewed release environment')
    commit = environment.get('GITHUB_SHA', '')
    if not re.fullmatch(r'[a-f0-9]{40}', commit):
        raise ValueError('An exact committed source is required')
    version_numbers(policy['version'])
    return policy['version'], commit


def verified_artifacts(folder, version, commit, require_clean=True):
    version_numbers(version)
    data = json.loads((folder / 'release.json').read_text())
    if (data['version'] != version or data['commit'] != commit
            or data.get('addon_version') != version_numbers(version)):
        raise ValueError('Artifact version/commit does not match publication request')
    if require_clean and data.get('source_state') != 'clean':
        raise ValueError('Release artifacts must come from a clean committed source tree')
    names = {f'{name}-{version}.zip' for name in ('AlphaSquadUI', 'AlphaSquadBuildShare')}
    if set(data['archives']) != names:
        raise ValueError('Unexpected archive inventory')
    expected = names | {'release.json', 'RELEASE_NOTES.md'}
    digests = {}
    for line in (folder / 'SHA256SUMS').read_text().splitlines():
        match = re.fullmatch(r'([a-f0-9]{64})  ([A-Za-z0-9_.-]+)', line)
        if not match or match[2] in digests:
            raise ValueError('Invalid checksum manifest')
        digests[match[2]] = match[1]
    if set(digests) != expected or {p.name for p in folder.iterdir()} != expected | {'SHA256SUMS'}:
        raise ValueError('Artifact bundle contains unexpected or missing files')
    for name, digest in digests.items():
        if (folder / name).is_symlink() or sha256(folder / name) != digest:
            raise ValueError('Artifact checksum mismatch')
    for name, digest in data['archives'].items():
        if digest != digests[name]:
            raise ValueError('Archive digest differs from release metadata')
        package = name.split('-')[0]
        members = inspect_archive(folder / name, package)
        manifest = members[f'{package}/{package}.txt'].decode()
        if not re.search(r'^## Version: ' + re.escape(version) + '$', manifest, re.M):
            raise ValueError('Archive manifest version mismatch')
        if not re.search(r'^## AddOnVersion: ' + str(version_numbers(version)) + '$', manifest, re.M):
            raise ValueError('Archive numeric version mismatch')
        if f'{package}/LICENSE' not in members:
            raise ValueError('Package license is missing')
    return sorted(expected | {'SHA256SUMS'})


def verify_existing_release(release, target, commit, paths, folder):
    """Never overwrite a version or carry unvalidated assets into publication."""
    if target is not None and target != commit:
        raise ValueError('Existing release tag points to a different commit; use a new version')
    if release is None:
        return {}
    if release['draft'] and release['target_commitish'] != commit:
        raise ValueError('Existing draft belongs to a different source commit')
    listed = release['assets']
    assets = {asset['name']: asset for asset in listed}
    if len(assets) != len(listed) or not set(assets).issubset(paths):
        raise ValueError('Existing release has unexpected or duplicate assets; manual review is required')
    if not release['draft'] and (target != commit or set(assets) != set(paths)):
        raise ValueError('Published release does not match this committed artifact bundle')
    for name, asset in assets.items():
        if asset.get('digest') != 'sha256:' + sha256(folder / name):
            raise ValueError('An existing release asset differs; manual review is required')
    return assets


class GitHub:
    def __init__(self, repository, token):
        self.root = f'https://api.github.com/repos/{repository}'
        self.token = token

    def request(self, path, method='GET', data=None, content_type='application/json', missing_ok=False):
        url = path if path.startswith('https://') else self.root + path
        parsed = urllib.parse.urlsplit(url)
        if parsed.scheme != 'https' or parsed.hostname not in {'api.github.com', 'uploads.github.com'}:
            raise ValueError('Unexpected GitHub endpoint')
        payload = (json.dumps(data).encode() if data is not None and content_type == 'application/json' else data)
        request = urllib.request.Request(url, data=payload, method=method, headers={
            'Authorization': 'Bearer ' + self.token,
            'Accept': 'application/vnd.github+json', 'X-GitHub-Api-Version': '2022-11-28',
            'Content-Type': content_type, 'User-Agent': 'AlphaSquadUI-release',
        })
        try:
            with urllib.request.build_opener(NoRedirect()).open(request, timeout=60) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            if missing_ok and error.code == 404:
                return None
            # Never print headers, response bodies or authorization values.
            raise RuntimeError(f'GitHub {method} request failed: HTTP {error.code}') from None

    def tag_commit(self, tag):
        ref = self.request('/git/ref/tags/' + tag, missing_ok=True)
        if ref is None:
            return None
        obj = ref['object']
        for _ in range(4):
            if obj['type'] == 'commit':
                return obj['sha']
            if obj['type'] != 'tag':
                break
            obj = self.request('/git/tags/' + obj['sha'])['object']
        raise ValueError('Release tag does not resolve to a commit')

    def release_by_tag(self, tag):
        """Find published releases and pending-tag drafts without creating duplicates."""
        # The by-tag endpoint only finds published releases. Authenticated release
        # listings also include drafts, including drafts whose tag does not exist.
        published = self.request('/releases/tags/' + tag, missing_ok=True)
        matches = {} if published is None else {published['id']: published}
        page = 1
        while True:
            listed = self.request(f'/releases?per_page=100&page={page}')
            for release in listed:
                if release['tag_name'] == tag:
                    matches[release['id']] = release
            if len(matches) > 1:
                raise ValueError('Multiple releases use this tag; manual review is required')
            if len(listed) < 100:
                break
            page += 1
        if not matches:
            return None
        release_id = next(iter(matches))
        # Refresh the inventory before verifying source and existing asset hashes.
        release = self.request('/releases/' + str(release_id))
        if release['id'] != release_id or release['tag_name'] != tag:
            raise ValueError('Release changed during lookup; manual review is required')
        return release


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('artifacts', type=Path)
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()
    policy = json.loads((ROOT / 'tooling/release-policy.json').read_text())
    version, commit = publication_request(policy, os.environ)
    repository = os.environ['GITHUB_REPOSITORY']
    paths = verified_artifacts(args.artifacts, version, commit, require_clean=True)
    if args.dry_run:
        print(f'Publication inputs verified: v{version}, {commit[:12]}, {len(paths)} assets. No network writes.')
        return
    github = GitHub(repository, os.environ['GH_TOKEN'])
    tag = 'v' + version
    release = github.release_by_tag(tag)
    target = github.tag_commit(tag)
    assets = verify_existing_release(release, target, commit, paths, args.artifacts)
    if release is not None and not release['draft']:
        print(f'{tag} already matches {commit} and all validated assets; no modification is needed.')
        return
    if release is None:
        release = github.request('/releases', 'POST', {
            'tag_name': tag, 'target_commitish': commit,
            'name': f'Alpha Squad UI {version}', 'draft': True, 'prerelease': False,
            'body': (args.artifacts / 'RELEASE_NOTES.md').read_text(),
        })
    for name in paths:
        path = args.artifacts / name
        if name in assets:
            continue
        url = release['upload_url'].split('{')[0] + '?' + urllib.parse.urlencode({'name': name})
        asset = github.request(url, 'POST', path.read_bytes(), 'application/octet-stream')
        if asset.get('digest') != 'sha256:' + sha256(path):
            raise ValueError('GitHub uploaded-asset digest mismatch; draft remains unpublished')
    # Re-read the complete server inventory before making a resumable draft
    # public. It must contain all and only the reviewed assets.
    completed = github.request('/releases/' + str(release['id']))
    inventory = verify_existing_release(completed, github.tag_commit(tag), commit, paths, args.artifacts)
    if set(inventory) != set(paths):
        raise ValueError('Draft asset inventory is incomplete; draft remains unpublished')
    published = github.request('/releases/' + str(release['id']), 'PATCH', {'draft': False, 'make_latest': 'true'})
    if github.tag_commit(tag) != commit:
        raise ValueError('Published tag verification failed')
    print('Published ' + published['html_url'])


if __name__ == '__main__':
    try:
        main()
    except (ValueError, RuntimeError, KeyError, OSError) as error:
        print(f'Release stopped: {error}', file=sys.stderr)
        sys.exit(1)
