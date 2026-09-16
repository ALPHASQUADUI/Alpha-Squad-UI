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
from package_utils import collect_package, inspect_archive, sha256, version_numbers, write_archive
from publish_release import publication_request, verified_artifacts, verify_existing_release
from security_scan import approved_identity, commit_message_findings, findings, public_email, scan
from validate import clean_source


class ReleaseIntegrity(unittest.TestCase):
    def test_publication_requires_manual_main_version_and_every_prerequisite(self):
        policy = {'repository': 'example/fixture', 'source_branch': 'main', 'version': '3.3.1',
                  'publish': True, 'release_environment': 'release',
                  'environment_review_configured': True, 'protocol_ids_reserved': True,
                  'protocol_coexistence_validated': True, 'native_acceptance_complete': True}
        environment = {'GITHUB_REPOSITORY': 'example/fixture', 'GITHUB_REF': 'refs/heads/main',
                       'GITHUB_EVENT_NAME': 'workflow_dispatch', 'GITHUB_SHA': 'a' * 40,
                       'ASUI_RELEASE_REQUESTED': 'true', 'ASUI_RELEASE_VERSION': '3.3.1'}
        self.assertEqual(publication_request(policy, environment), ('3.3.1', 'a' * 40))
        for key, value in (('GITHUB_EVENT_NAME', 'push'), ('GITHUB_REF', 'refs/heads/dev'),
                           ('ASUI_RELEASE_VERSION', '3.3.0'), ('ASUI_RELEASE_REQUESTED', 'false')):
            with self.subTest(key=key), self.assertRaises(ValueError):
                publication_request(policy, {**environment, key: value})
        for key in ('publish', 'environment_review_configured', 'protocol_ids_reserved',
                    'protocol_coexistence_validated', 'native_acceptance_complete'):
            with self.subTest(key=key), self.assertRaises(ValueError):
                publication_request({**policy, key: False}, environment)

    def test_uncommitted_artifacts_cannot_publish(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            self.bundle(root)
            metadata = json.loads((root / 'release.json').read_text())
            metadata['source_state'] = 'modified'
            (root / 'release.json').write_text(json.dumps(metadata))
            with self.assertRaisesRegex(ValueError, 'clean committed'):
                verified_artifacts(root, '3.3.0', 'a' * 40)

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

    def test_package_rejects_ignored_data_and_scans_the_final_bytes(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / 'AlphaSquadUI'
            source.mkdir()
            (root / 'LICENSE').write_text('Fixture license')
            (source / 'AlphaSquadUI.txt').write_text('## Version: 3.3.0\nRuntime.lua\n')
            (source / 'Runtime.lua').write_text('return true')
            clean = collect_package(source, 'AlphaSquadUI', root / 'LICENSE')
            for name in ('Logs/session.log', 'SavedVariables/account.lua', '.env', 'Runtime.lua.bak', 'extra.txt'):
                extra = source / name
                extra.parent.mkdir(parents=True, exist_ok=True)
                extra.write_text('Unreviewed fixture')
                with self.subTest(name=name), self.assertRaises(ValueError):
                    collect_package(source, 'AlphaSquadUI', root / 'LICENSE')
                extra.unlink()
                archive = root / 'bad.zip'
                write_archive(archive, {**clean, 'AlphaSquadUI/' + name: b'Unreviewed fixture'})
                with self.subTest(name=name), self.assertRaises(ValueError):
                    inspect_archive(archive, 'AlphaSquadUI')
            secret = ('gh' + 'p_' + 'Z' * 36).encode()
            write_archive(root / 'bad.zip', {**clean, 'AlphaSquadUI/Runtime.lua': secret})
            with self.assertRaisesRegex(ValueError, 'privacy scan'):
                inspect_archive(root / 'bad.zip', 'AlphaSquadUI')
            (source / 'Runtime.lua').write_bytes(secret)
            with self.assertRaisesRegex(ValueError, 'privacy scan'):
                collect_package(source, 'AlphaSquadUI', root / 'LICENSE')


class PrivacyBoundaries(unittest.TestCase):
    def test_public_project_mailbox_requires_the_exact_address_and_approved_alias(self):
        mailbox = 'info@alphasquadeso.com'
        self.assertTrue(public_email(mailbox))
        self.assertTrue(public_email(mailbox, metadata=True))
        self.assertEqual(findings(('Project contact: ' + mailbox).encode()), [])
        for name in ('SeRuM1', 'adi684'):
            self.assertTrue(approved_identity(name, mailbox))
        for name in ('Unknown Fixture', 'GitHub', 'dependabot[bot]', 'github-actions[bot]'):
            self.assertFalse(approved_identity(name, mailbox))
        other_addresses = [
            'other' + '@' + 'alphasquadeso.com',
            'info+fixture' + '@' + 'alphasquadeso.com',
            'info' + '@' + 'mail.alphasquadeso.com',
            'info' + '@' + 'alphasquadeso.com.example.com',
            'info' + '@' + 'alphasquadeso.co',
            'person' + '@' + 'mail.example.com',
            mailbox.upper(),
        ]
        for address in other_addresses:
            self.assertFalse(public_email(address))
            self.assertFalse(public_email(address, metadata=True))
            self.assertFalse(approved_identity('SeRuM1', address))
            self.assertEqual(findings(address.encode()), [(1, 'non-public email')])
        self.assertFalse(approved_identity('SeRuM1', 'person@example.com'))
        self.assertEqual(findings(mailbox.encode(), private_terms=[mailbox]), [(1, 'private term')])

    def test_public_project_mailbox_passes_real_commit_checks_without_allowing_other_names(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            def git(*args):
                return subprocess.run(['git', *args], cwd=root, check=True,
                                      stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout.decode().strip()
            git('init', '-q')
            git('config', 'user.name', 'SeRuM1')
            git('config', 'user.email', 'info@alphasquadeso.com')
            (root / 'file.txt').write_text('Public contact: info@alphasquadeso.com')
            git('add', '.')
            git('commit', '-qm', 'Public project identity')
            self.assertEqual(scan(root=root), [])
            baseline = git('rev-parse', 'HEAD')
            git('commit', '--allow-empty', '-qm', 'Public co-author\n\nCo-authored-by: adi684 <info@alphasquadeso.com>')
            self.assertEqual(scan(root=root, base=baseline), [])
            git('config', 'user.name', 'Unknown Fixture')
            git('commit', '--allow-empty', '-qm', 'Unapproved alias fixture')
            problems = scan(root=root, base=baseline)
            self.assertTrue(any('author must use an approved public identity' in item for item in problems))
            self.assertTrue(any('committer must use an approved public identity' in item for item in problems))
            self.assertNotIn('Unknown Fixture', repr(problems))
            self.assertNotIn('info@alphasquadeso.com', repr(problems))

    def test_dependabot_signoff_exception_requires_exact_trailer_and_approved_metadata(self):
        mailbox = 'support' + '@' + 'github.com'
        signoff = 'Signed-off-by: dependabot[bot] <' + mailbox + '>'
        bot = ('dependabot[bot]', '123+dependabot[bot]@users.noreply.github.com')
        metadata = [bot, ('GitHub', 'noreply@github.com')]
        message = ('Update reviewed dependencies\n\n' + signoff + '\n').encode()
        self.assertEqual(commit_message_findings(message, metadata), [])
        self.assertFalse(public_email(mailbox))
        self.assertFalse(public_email(mailbox, metadata=True))
        self.assertFalse(approved_identity('dependabot[bot]', mailbox))
        self.assertEqual(findings(message), [(3, 'non-public email')])
        invalid_messages = [
            'Update dependencies\n\n' + signoff + ' added text',
            'Update dependencies\n\n' + signoff.lower(),
            'Quoted signature:\n> ' + signoff,
            signoff + '\n\nUnrelated later message',
            signoff + '\n' + signoff,
            'Update dependencies\n\nSigned-off-by: another-bot <' + mailbox + '>',
        ]
        for text in invalid_messages:
            with self.subTest(case=invalid_messages.index(text)):
                self.assertTrue(any(rule == 'non-public email' for _, rule in
                                    commit_message_findings(text.encode(), metadata)))
        for authors in ([('SeRuM1', '123+adi684@users.noreply.github.com'), metadata[1]],
                        [('dependabot[bot]', mailbox), metadata[1]],
                        [bot, ('Unknown Fixture', 'noreply@github.com')],
                        [bot, metadata[1], ('Unknown Fixture', bot[1])]):
            self.assertTrue(any(rule == 'non-public email' for _, rule in
                                commit_message_findings(message, authors)))

    def test_dependabot_exception_keeps_secrets_other_mailboxes_and_private_terms(self):
        mailbox = 'support' + '@' + 'github.com'
        other_mailbox = 'fixture' + '@' + 'github.com'
        token = 'gh' + 'p_' + 'D' * 36
        signoff = 'Signed-off-by: dependabot[bot] <' + mailbox + '>'
        metadata = [('dependabot[bot]', '123+dependabot[bot]@users.noreply.github.com'),
                    ('GitHub', 'noreply@github.com')]
        message = (token + '\n' + other_mailbox + '\n\n' + signoff).encode()
        result = commit_message_findings(message, metadata, private_terms=[mailbox])
        self.assertIn((1, 'GitHub credential'), result)
        self.assertIn((2, 'non-public email'), result)
        self.assertIn((4, 'private term'), result)
        self.assertNotIn((4, 'non-public email'), result)
        self.assertNotIn(mailbox, repr(result))
        self.assertNotIn(other_mailbox, repr(result))
        self.assertNotIn(token, repr(result))

    def test_dependabot_exception_applies_to_commit_messages_only(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            def git(*args):
                return subprocess.run(['git', *args], cwd=root, check=True,
                                      stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout.decode().strip()
            git('init', '-q')
            git('config', 'user.name', 'dependabot[bot]')
            git('config', 'user.email', '123+dependabot[bot]@users.noreply.github.com')
            (root / 'file.txt').write_text('Fixture source')
            git('add', '.')
            git('commit', '-qm', 'Source fixture')
            baseline = git('rev-parse', 'HEAD')
            mailbox = 'support' + '@' + 'github.com'
            signoff = 'Signed-off-by: dependabot[bot] <' + mailbox + '>'
            git('commit', '--allow-empty', '-qm', 'Update dependencies\n\n' + signoff)
            self.assertEqual(scan(root=root, base=baseline), [])
            (root / 'file.txt').write_text(signoff)
            problems = scan(root=root, base=baseline)
            self.assertTrue(any('file.txt' in problem and 'non-public email' in problem for problem in problems))
            self.assertNotIn(mailbox, repr(problems))
            (root / 'file.txt').write_text('Fixture source')
            git('commit', '--allow-empty', '-qm', 'Update dependencies\n\nCo-authored-by: dependabot[bot] <'
                + mailbox + '>\n' + signoff)
            problems = scan(root=root, base=baseline)
            self.assertTrue(any('co-author must use' in problem for problem in problems))
            self.assertTrue(any('non-public email' in problem for problem in problems))
            self.assertNotIn(mailbox, repr(problems))

    def test_public_names_must_match_their_approved_noreply_login(self):
        self.assertTrue(approved_identity('SeRuM1', '123+adi684@users.noreply.github.com'))
        self.assertTrue(approved_identity('GitHub', 'noreply@github.com'))
        self.assertFalse(approved_identity('Unapproved Fixture', '123+adi684@users.noreply.github.com'))
        self.assertFalse(approved_identity('SeRuM1', '123+unapproved@users.noreply.github.com'))
        self.assertFalse(approved_identity('SeRuM1', 'noreply@github.com'))

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
            policy = {'Fixture': {'fixture'}}
            self.assertEqual(scan(root=root, identities=policy), [])
            problems = scan(root=root, base=baseline, identities=policy)
            self.assertTrue(any(introduced[:12] in item and 'GitHub credential' in item for item in problems))
            self.assertFalse(any('author must' in item for item in problems))
            self.assertNotIn(token, repr(problems))

    def test_first_branch_history_and_coauthors_are_checked_without_legacy_reopening(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            def git(*args):
                return subprocess.run(['git', *args], cwd=root, check=True,
                                      stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout.decode().strip()
            git('init', '-q', '-b', 'main')
            git('config', 'user.name', 'Fixture')
            git('config', 'user.email', 'historical' + '@' + 'private.test')
            (root / 'file.txt').write_text('safe')
            git('add', '.')
            git('commit', '-qm', 'Historical identity')
            git('checkout', '-qb', 'new-module')
            git('config', 'user.email', '123+fixture@users.noreply.github.com')
            token = 'gh' + 'p_' + 'C' * 36
            (root / 'file.txt').write_text(token)
            git('commit', '-qam', 'Introduce fixture')
            introduced = git('rev-parse', 'HEAD')
            (root / 'file.txt').write_text('safe again')
            git('commit', '-qam', 'Remove fixture\n\nCo-authored-by: Unknown Fixture <123+fixture@users.noreply.github.com>')
            problems = scan(root=root, identities={'Fixture': {'fixture'}})
            self.assertTrue(any(introduced[:12] in item and 'GitHub credential' in item for item in problems))
            self.assertTrue(any('co-author must use' in item for item in problems))
            self.assertFalse(any(': author must use' in item for item in problems))
            self.assertNotIn(token, repr(problems))
            self.assertNotIn('Unknown Fixture', repr(problems))

    def test_optional_private_terms_never_appear_in_diagnostics(self):
        term = 'Synthetic' + 'PrivateAlias'
        matches = findings(('display=' + term).encode(), private_terms=[term])
        self.assertEqual(matches, [(1, 'private term')])
        self.assertNotIn(term, repr(matches))

    def test_clean_provenance_detects_assume_unchanged_modified_input(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            def git(*args):
                return subprocess.run(['git', *args], cwd=root, check=True,
                                      stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout
            git('init', '-q')
            git('config', 'user.name', 'Fixture')
            git('config', 'user.email', '123+fixture@users.noreply.github.com')
            (root / 'source.lua').write_text('return true')
            git('add', '.')
            git('commit', '-qm', 'Source fixture')
            self.assertTrue(clean_source(root))
            git('update-index', '--assume-unchanged', 'source.lua')
            (root / 'source.lua').write_text('return false')
            self.assertEqual(git('status', '--porcelain'), b'')
            self.assertFalse(clean_source(root))


if __name__ == '__main__':
    unittest.main()
