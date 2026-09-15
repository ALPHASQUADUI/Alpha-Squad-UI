# Repository operations

## Required validation

The desired branch rule is versioned in [repository-policy.json](../tooling/repository-policy.json). It preserves pull requests, blocks deletion and force pushes, requires resolved review conversations, and accepts `validate-and-package` only from the GitHub Actions application. The branch must be current before merging.

This file is a reviewable configuration, not evidence that GitHub has applied it. Applying repository rules requires an administrator connection; a workflow's ordinary `GITHUB_TOKEN` does not grant that permission. Do not add an administrator token to addon files or to a pull-request workflow.

After the check has run successfully, an administrator can import the rule in **Settings → Rules → Rulesets**, or update the existing rule with the reviewed JSON using the GitHub REST API. Re-read the active rules afterward. Keep the existing rule's scope and do not create bypass actors. A second-person approval is not mandatory for this single-maintainer policy; CODEOWNERS requests review on sensitive files without claiming to enforce it.

## Public project information

[repository-metadata.json](../tooling/repository-metadata.json) contains the description, website and topics for GitHub's About section. Set these values using an administrator connection and verify the public repository page. Editing the JSON alone does not update About.

Enable private vulnerability reporting in the repository's Security settings when available. The fallback private reporting route is described in [SECURITY.md](../SECURITY.md). Repository/account security settings and the presence of this policy are separate checks.

## Commit identity and historical privacy

Use the maintainer's public pseudonym and a GitHub-provided `noreply` address for author and committer metadata. Enable GitHub's email privacy and blocked-private-email-push options in the account settings. Local identity configuration does not change those account settings.

Changing future commit identity does not remove previous metadata. Handle a historical exposure privately: inventory affected reachable commits without printing their values, make a private recovery copy, prepare and compare a rewritten mirror, and obtain explicit approval for the exact affected refs before any forced update. A rewrite changes descendant commit IDs and can disrupt open pull requests, tags, forks and existing clones. Do not remove branch protections or rewrite release history as an incidental part of a feature update. Public clones cannot be recalled.

No sensitive historical values belong in this document, a public issue, a commit message or a scanner log. The security check rejects new exposures while the historical remediation plan remains separate.

## Distribution and recovery

Publish the same versioned archives that completed validation, with SHA256 checksums and source provenance. Do not overwrite an existing release or silently move its tag. A correction receives a new version. Keep release notes precise about user-visible behavior and any native-client or library-compatibility checks not yet recorded.

Restore a previous addon package if needed while preserving a private SavedVariables backup. Do not downgrade saved data blindly if a future version introduces an incompatible migration. Current supported settings retain their existing namespaces.
