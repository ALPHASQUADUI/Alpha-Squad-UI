# Validation and release tooling

Run `python3 tooling/validate.py` with Python 3.9 or newer, Git, Lua 5.1 and
Lua 5.4 available. `LUA51` and `LUA54` may name explicit executables. The output
directory defaults to `dist`; use `--output-dir /path/to/bundle` to change it.

The gate checks recognizable credential formats, public identity policy, changed
commit history, whitespace, version encoding, manifests, XML and Python trust
boundary tests. It builds each installable archive once, extracts it safely,
and runs the Lua regression suites against the extracted runtime files under
both interpreters. The standalone sender is tested from its own extracted ZIP.
Runtime files must appear in the manifest. The only additional package assets
are the explicit reviewed README paths and LICENSE in `package_utils.py`.
Unknown files under the addon folder fail packaging, including Git-ignored
logs, real SavedVariables, backups and credentials. The Media placeholder is
excluded. Archive inspection repeats the allowlist and security/privacy scan
against the final payload, including the transformed companion.
The two packages include the project license. Passing automation does not claim
native-client rendering, live group performance or protocol coexistence.

The retained bundle contains:

- `AlphaSquadUI-VERSION.zip` and `AlphaSquadBuildShare-VERSION.zip`.
- `release.json`: source commit, clean/modified source state, version and archive hashes.
- `RELEASE_NOTES.md`: the version's reviewed notes from `releases/`.
- `SHA256SUMS`: hashes for the other four files.

Archive order, permissions and timestamps are deterministic. Release assets are
the validated files, never a later rebuild. ZIP hashes establish integrity;
they are not independent proof of authorship. An artifact built from uncommitted
files is marked modified and cannot pass the publisher's provenance check.
Tracked inputs are compared with HEAD even when Git's assume-unchanged flag
would hide modifications from normal status output.

## Security and privacy gate

`python3 tooling/security_scan.py` checks the current tracked and nonignored
files. In CI it also reads the event's exact base/head commits, enforcing public
author, committer and co-author names matched to the approved public GitHub
noreply logins in `PUBLIC_IDENTITIES`. The maintainer also authorizes the exact
public project mailbox `info@alphasquadeso.com` with the aliases `SeRuM1` and
`adi684`; no domain-wide or arbitrary-address exception is granted. The gate scans changed blobs and commit
messages in every new commit. A secret introduced and removed in the same push
still fails. `--base COMMIT --head COMMIT` selects an explicit range locally.

An approved Dependabot commit may contain its exact standard `Signed-off-by`
trailer using GitHub's public support mailbox. Only a single exact final trailer
line is exempted from the email finding, and only when the author is the
approved Dependabot noreply identity and every author/committer/co-author
identity passes policy. This does not allow that mailbox elsewhere, in files,
in another author's message, or as author/committer/co-author metadata. Secret
patterns and optional private terms still scan the complete original message.

First-branch pushes, dispatches and ordinary local checks compare the complete
incoming history to the merge base with `origin/main` or local `main`. They
check HEAD if it is already included in main. If neither main ref is available,
the fallback checks HEAD only; CI fetches full history. Historical remediation
before that baseline remains a separate maintainer action.

An optional `--private-terms-file /local/path/terms.private.json` accepts a local
JSON list of sensitive strings of at least four characters. Keep it outside the
repository and never put real private names in public tests or policy. Matches,
including sensitive filenames, are redacted in diagnostics. The default scanner
cannot infer arbitrary private aliases. A permitted alias, project mailbox or
noreply address does not prove account ownership; verify that separately before publication.
These patterns complement GitHub secret scanning and human review; they cannot
identify all confidential data.

The required check name remains `validate-and-package`. Security/privacy runs
inside that job. Required-check enforcement itself is a repository setting;
the desired policy in `repository-policy.json` is not applied by validation.
`tag-policy.json` is a separate desired ruleset: allow initial creation of
version tags, then deny updates, deletions and force pushes. An administrator
must review and apply both rulesets and verify their effective state. Neither
file changes GitHub settings by itself. Enable and verify GitHub secret scanning
and push protection separately when available.

## Publication

Publication is disabled by default (`publish: false`). Pushes and pull requests
only validate. After a separate explicit release authorization, a maintainer can
enable the exact numeric version in `release-policy.json` and request it using
`workflow_dispatch`, `publish=true`, from `main`. The requested version must
match the policy. A normal manual validation keeps `publish=false`.

All prerequisite fields must be true before a release request can pass the
read-only preflight: protocol IDs formally reserved, coexistence validated,
native client acceptance completed, and the release environment protection
configured. These are evidence-backed maintainer attestations, not automatic
proof. They remain false until those external tasks are actually completed.
Provisional IDs cannot pass the stable publication gate.

Before enabling publication, an administrator must configure the `release`
environment with required reviewers, main-only deployment and no unreviewed
bypass. The job references that environment, but a name alone creates no review
protection. Configure reviewers appropriate for the project; do not pretend the
JSON attestation applies GitHub settings. Verify availability for the account's
plan and inspect the effective environment rules.

The release job alone receives `contents: write`, downloads the current run's
artifact, and runs `python3 tooling/publish_release.py dist`. The publisher checks
the exact source commit, clean provenance, manifest versions, license, complete
inventory and hashes. It creates a draft, uploads the reviewed files, verifies
GitHub's asset digests and complete inventory, then publishes the release and
verifies the tag. The commit selected for the tag is the validated source commit.

An existing published version must have that same commit and identical assets.
The publisher never replaces published tags or files. It searches the authenticated
release listing across all pages as well as the published-tag endpoint, so an
interrupted draft can be found even before its tag exists. Multiple release IDs
claiming the same tag stop publication for review. Interrupted drafts can
resume only when their source and existing assets match; extra, duplicate or
different assets stop publication for review. A changed source needs a new
version. Native acceptance evidence and protocol reservation/coexistence evidence
must support the policy before publishing. Release notes must not overstate them.

Follow the ordered [public release procedure](../docs/REPOSITORY_OPERATIONS.md#public-release-procedure)
for registry evidence, repository settings, manual dispatch and recovery.

`--dry-run` validates the publication inputs without network requests. It still
requires the matching GitHub event/ref/repository/SHA environment and clean
artifacts. Publication credentials are never needed for this dry run.

## External actions

Official actions are pinned to the verified release commits rather than mutable
major-version tags. Dependabot monitors those references weekly. Checkout does
not persist Git credentials. Validation uses a read-only repository token; the
publisher denies redirects before sending any authorization to another endpoint.

- [Checkout v7.0.1](https://github.com/actions/checkout/tree/3d3c42e5aac5ba805825da76410c181273ba90b1)
- [Upload Artifact v7.0.1](https://github.com/actions/upload-artifact/tree/043fb46d1a93c77aae656e7c1c64a875d1fc6a0a)
- [Download Artifact v8.0.1](https://github.com/actions/download-artifact/tree/3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c)

These versions run on Node 24 (Actions Runner 2.327.1 or newer). The hosted
Ubuntu 24.04 workflow retains zipped uploads and extraction by exact artifact
name directly into `dist`. Digest mismatches now fail the download by default.
The new checkout safeguard for `pull_request_target` and `workflow_run` does
not require opting out: this workflow uses neither of those triggers.

See GitHub's [secure workflow guidance](https://docs.github.com/en/actions/reference/security/secure-use)
and [release asset API](https://docs.github.com/en/rest/releases/assets).
