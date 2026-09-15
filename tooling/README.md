# Validation and release tooling

Run `python3 tooling/validate.py` with Python 3.9 or newer, Git, Lua 5.1 and
Lua 5.4 available. `LUA51` and `LUA54` may name explicit executables. The output
directory defaults to `dist`; use `--output-dir /path/to/bundle` to change it.

The gate checks recognizable credential formats, public email policy, changed
commit history, whitespace, version encoding, manifests, XML and Python trust
boundary tests. It builds each installable archive once, extracts it safely,
and runs the Lua regression suites against the extracted runtime files under
both interpreters. The standalone sender is tested from its own extracted ZIP.
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

## Security and privacy gate

`python3 tooling/security_scan.py` checks the current tracked and nonignored
files. In CI it also reads the event's exact base/head commits, enforcing public
GitHub noreply author/committer addresses and scanning changed blobs and commit
messages in every new commit. A secret introduced and removed in the same push
still fails. `--base COMMIT --head COMMIT` selects an explicit range locally.

First-branch pushes, dispatches and ordinary local checks validate HEAD without
reopening known historical privacy incidents. Historic remediation is a separate
maintainer action. Diagnostics name the file/commit and rule, never the matching
credential or private address. These targeted patterns complement GitHub's own
secret scanning and human review; they cannot identify all confidential data.

The required check name remains `validate-and-package`. Security/privacy runs
inside that job. Required-check enforcement itself is a repository setting;
the desired policy in `repository-policy.json` is not applied by validation.

## Publication

`release-policy.json` is an explicit authorization marker for one repository,
source ref and numeric version. Only a push to that authorized ref may enter
the release job after validation succeeds. Pull requests and manual validation
runs never publish. Changing the version requires an intentional policy update.

The release job alone receives `contents: write`, downloads the current run's
artifact, and runs `python3 tooling/publish_release.py dist`. The publisher checks
the exact source commit, clean provenance, manifest versions, license, complete
inventory and hashes. It creates a draft, uploads the reviewed files, verifies
GitHub's asset digests and complete inventory, then publishes the release and
verifies the tag. The commit selected for the tag is the validated source commit.

An existing published version must have that same commit and identical assets.
The publisher never replaces published tags or files. Interrupted drafts can
resume only when their source and existing assets match; extra, duplicate or
different assets stop publication for review. A changed source needs a new
version. Native acceptance status and provisional transport limits remain in
the release notes and must never be presented as completed checks.

`--dry-run` validates the publication inputs without network requests. It still
requires the matching GitHub event/ref/repository/SHA environment and clean
artifacts. Publication credentials are never needed for this dry run.

## External actions

Official actions are pinned to the verified release commits rather than mutable
major-version tags. Dependabot monitors those references weekly. Checkout does
not persist Git credentials. Validation uses a read-only repository token; the
publisher denies redirects before sending any authorization to another endpoint.

- [Checkout v6.1.0](https://github.com/actions/checkout/tree/d23441a48e516b6c34aea4fa41551a30e30af803)
- [Upload Artifact v6.0.0](https://github.com/actions/upload-artifact/tree/b7c566a772e6b6bfb58ed0dc250532a479d7789f)
- [Download Artifact v6.0.0](https://github.com/actions/download-artifact/tree/018cc2cf5baa6db3ef3c5f8a56943fffe632ef53)

See GitHub's [secure workflow guidance](https://docs.github.com/en/actions/reference/security/secure-use)
and [release asset API](https://docs.github.com/en/rest/releases/assets).
