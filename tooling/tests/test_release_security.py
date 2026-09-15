"""Exercise trust boundaries with disposable files/repos, never real credentials."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import warnings
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from package_utils import inspect_archive, sha256, version_numbers, write_archive
from publish_release import verified_artifacts, verify_existing_release
from security_scan import findings, public_email, scan


class ReleaseIntegrity(unittest.TestCase):
    def test_published_release_must_match_current_commit(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            with self.assertRaisesRegex(ValueError, 'different commit'):
                verify_existing_release({'draft': False, 'assets': []}, 'b' * 40, 'a' * 40, [], root)

    def test_draft_cannot_publish_unvalidated_or_duplicate_assets(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / 'safe.zip').write_bytes(b'validated')
            safe = {'name': 'safe.zip', 'digest': 'sha256:' + sha256(root / 'safe.zip')}
            for listed in ([safe, {'name': 'unreviewed.txt'}], [safe, safe]):
                draft = {'draft': True, 'target_commitish': 'a' * 40, 'assets': listed}
                with self.assertRaisesRegex(ValueError, 'unexpected or duplicate'):
                    verify_existing_release(draft, None, 'a' * 40, ['safe.zip'], root)
            draft = {'draft': True, 'target_commitish': 'a' * 40, 'assets': [safe]}
            self.assertEqual(list(verify_existing_release(draft, None, 'a' * 40, ['safe.zip'], root)), ['safe.zip'])

    def bundle(self, folder):
        names = {}
        for package in ('AlphaSquadUI', 'AlphaSquadBuildShare'):
            path = folder / f'{package}-3.3.0.zip'
            write_archive(path, {
                f'{package}/{package}.txt': b'## Version: 3.3.0\n## AddOnVersion: 30300\n',
                f'{package}/LICENSE': b'License fixture',
            })
            names[path.name] = sha256(path)
        (folder / 'release.json').write_text(json.dumps({
            'version': '3.3.0', 'addon_version': 30300, 'commit': 'a' * 40, 'archives': names, 'source_state': 'clean',
        }))
        (folder / 'RELEASE_NOTES.md').write_text('Reviewed release notes.')
        members = sorted(folder.iterdir())
        (folder / 'SHA256SUMS').write_text(''.join(f'{sha256(p)}  {p.name}\n' for p in members))

    def test_exact_bundle_and_post_validation_tampering(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            self.bundle(root)
            self.assertEqual(len(verified_artifacts(root, '3.3.0', 'a' * 40)), 5)
            with (root / 'AlphaSquadUI-3.3.0.zip').open('ab') as file:
                file.write(b'tampered after validation')
            with self.assertRaisesRegex(ValueError, 'checksum mismatch'):
                verified_artifacts(root, '3.3.0', 'a' * 40)

    def test_wrong_commit_and_extra_asset_are_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            self.bundle(root)
            with self.assertRaisesRegex(ValueError, 'version/commit'):
                verified_artifacts(root, '3.3.0', 'b' * 40)
            (root / 'unexpected.txt').write_text('not validated')
            with self.assertRaisesRegex(ValueError, 'unexpected or missing'):
                verified_artifacts(root, '3.3.0', 'a' * 40)

    def test_unsafe_zip_paths_and_duplicate_members(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / 'bad.zip'
            manifest = 'AlphaSquadUI/AlphaSquadUI.txt'
            for member in ('AlphaSquadUI/../../outside', '/AlphaSquadUI/outside', 'Other/data', 'AlphaSquadUI\\outside'):
                write_archive(path, {manifest: b'', member: b'unsafe'})
                with self.assertRaisesRegex(ValueError, 'unsafe'):
                    inspect_archive(path, 'AlphaSquadUI')
            with warnings.catch_warnings():
                warnings.simplefilter('ignore', UserWarning)
                with zipfile.ZipFile(path, 'w') as archive:
                    archive.writestr(manifest, b'first')
                    archive.writestr(manifest, b'other')
            with self.assertRaisesRegex(ValueError, 'duplicate'):
                inspect_archive(path, 'AlphaSquadUI')

    def test_reproducible_archives_and_eso_version_encoding(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write_archive(root / 'a.zip', {'AlphaSquadUI/b': b'two', 'AlphaSquadUI/a': b'one'})
            write_archive(root / 'b.zip', {'AlphaSquadUI/a': b'one', 'AlphaSquadUI/b': b'two'})
            self.assertEqual(sha256(root / 'a.zip'), sha256(root / 'b.zip'))
        self.assertEqual(version_numbers('3.3.0'), 30300)
        for version in ('3.100.0', '3.0.100', '03.3.0', '3.3.0-beta', '3.3'):
            with self.assertRaises(ValueError):
                version_numbers(version)


class PrivacyBoundaries(unittest.TestCase):
    def test_known_secret_patterns_and_email_policy(self):
        token = 'gh' + 'p_' + 'A' * 36
        matches = findings(('value=' + token).encode())
        self.assertTrue(any(rule == 'GitHub credential' for _, rule in matches))
        self.assertNotIn(token, repr(matches))
        self.assertTrue(public_email('noreply@github.com', metadata=True))
        self.assertTrue(public_email('123+maintainer@users.noreply.github.com', metadata=True))
        self.assertFalse(public_email('sample@example.com', metadata=True))
        self.assertFalse(public_email('person' + '@' + 'private.test', metadata=True))
        self.assertEqual(findings(b'Example: sample@example.com'), [])

    def test_scans_new_history_even_when_secret_removed_without_reopening_legacy_email(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)

            def git(*args):
                return subprocess.run(['git', *args], cwd=root, check=True,
                                      stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout.decode().strip()

            git('init', '-q')
            git('config', 'user.name', 'Fixture')
            git('config', 'user.email', 'legacy' + '@' + 'private.test')
            (root / 'file.txt').write_text('safe')
            git('add', '.')
            git('commit', '-qm', 'Historical identity')
            baseline = git('rev-parse', 'HEAD')
            git('config', 'user.email', '123+fixture@users.noreply.github.com')
            token = 'gh' + 'p_' + 'B' * 36
            (root / 'file.txt').write_text(token)
            git('commit', '-qam', 'Introduce fixture')
            introduced = git('rev-parse', 'HEAD')
            (root / 'file.txt').write_text('safe again')
            git('commit', '-qam', 'Remove fixture')
            self.assertEqual(scan(root=root), [])
            problems = scan(root=root, base=baseline)
            self.assertTrue(any(introduced[:12] in item and 'GitHub credential' in item for item in problems))
            self.assertFalse(any('author must' in item for item in problems))
            self.assertNotIn(token, repr(problems))


if __name__ == '__main__':
    unittest.main()
