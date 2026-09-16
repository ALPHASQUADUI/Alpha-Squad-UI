# Repository operations

## Required validation

The desired branch rule is versioned in [repository-policy.json](../tooling/repository-policy.json). It preserves pull requests, blocks deletion and force pushes, requires resolved review conversations, and accepts `validate-and-package` only from the GitHub Actions application. The branch must be current before merging.

This file is a reviewable configuration, not evidence that GitHub has applied it. Applying repository rules requires an administrator connection; a workflow's ordinary `GITHUB_TOKEN` does not grant that permission. Do not add an administrator token to addon files or to a pull-request workflow.

After the check has run successfully, an administrator can import the rule in **Settings → Rules → Rulesets**, or update the existing rule with the reviewed JSON using the GitHub REST API. Re-read the active rules afterward. Keep the existing rule's scope and do not create bypass actors. The maintainer must review and merge PRs manually. The assistant must never approve or merge, enable auto-merge, or update main directly. CODEOWNERS requests review on sensitive files; its presence alone does not prove enforcement.

## Public project information

[repository-metadata.json](../tooling/repository-metadata.json) contains the description, website and topics for GitHub's About section. Set these values using an administrator connection and verify the public repository page. Editing the JSON alone does not update About.

Enable private vulnerability reporting in the repository's Security settings when available. The fallback private reporting route is described in [SECURITY.md](../SECURITY.md). Repository/account security settings and the presence of this policy are separate checks.

## Commit identity and historical privacy

Use `SeRuM1 <info@alphasquadeso.com>` for new maintainer commits and verify both author and committer before publishing. The public project mailbox is explicitly authorized; noreply is not required. Keep private addresses out of new commits. Local identity configuration does not change account settings. Existing historical GitHub-generated identities remain covered by the scanner's separate allowlist.

Changing future commit identity does not remove previous metadata. Handle a historical exposure privately: inventory affected reachable commits without printing their values, make a private recovery copy, prepare and compare a rewritten mirror, and obtain explicit approval for the exact affected refs before any forced update. A rewrite changes descendant commit IDs and can disrupt open pull requests, tags, forks and existing clones. Do not remove branch protections or rewrite release history as an incidental part of a feature update. Public clones cannot be recalled.

No sensitive historical values belong in this document, a public issue, a commit message or a scanner log. The security check rejects new exposures while the historical remediation plan remains separate.

## Distribution and recovery

Publish the same versioned archives that completed validation, with SHA256 checksums and source provenance. Do not overwrite an existing release or silently move its tag. A correction receives a new version. Keep release notes precise about user-visible behavior and any native-client or library-compatibility checks not yet recorded.

Restore a previous addon package if needed while preserving a private SavedVariables backup. Do not downgrade saved data blindly if a future version introduces an incompatible migration. Current supported settings retain their existing namespaces.

## Public release procedure

The maintainer previously reported 3.3.1 stable. That acceptance does not apply to the 3.4 interface, its 3.4.1 dropdown hotfix or the 3.5.0 personal Ultimate candidate; the maintainer reported a native initialization failure in 3.4.0 and both the retained correction and the new native-slot replacement await retesting. The current cycle authorizes dev changes only, with no PR or release. The procedure below applies only after separate approval of the exact version and a verified human merge. Prerequisites requiring external evidence or administration must never be marked complete merely to make the workflow pass.

1. Verify and reserve the current protocol IDs and names through the [official registry](https://wiki.esoui.com/LibGroupBroadcast_IDs): `507` / `AlphaSquadSupportDetails` and `510` / `AlphaSquadSupportCoverage`, handler `AlphaSquadUI` / `ASUI`. Record the registry revision. These proposed values must be checked for availability before registration; declaring them in Lua does not reserve them.
2. Record the tested ESO/library versions and the native acceptance/coexistence results in [CLIENT_ACCEPTANCE.md](CLIENT_ACCEPTANCE.md), including other group-sharing addons and interrupted transfers. The existing maintainer stability report remains valid, but does not fill in unreported individual results.
3. In repository **Settings → Environments**, configure the `release` environment with an appropriate required reviewer, selected deployment branch `main`, and no unreviewed administrator bypass. For a single-maintainer project, do not enable a self-review prohibition unless another eligible reviewer is available. Verify the saved protection rules; naming the environment in YAML is insufficient.
4. Apply and verify the reviewed main and version-tag rules from [repository-policy.json](../tooling/repository-policy.json) and [tag-policy.json](../tooling/tag-policy.json), preserving existing protections and avoiding bypass actors. Version tags allow their initial creation, then block updates and deletion.
5. Once the evidence and settings are real, set the four prerequisite flags and `publish` to `true` in [release-policy.json](../tooling/release-policy.json). Keep `source_branch: main` and `version: 3.5.0`. Update the release notes to the actual completed status, then have a human review and merge the PR to `main` after successful CI. The assistant cannot perform this step.
6. In **Actions → Validate AlphaSquadUI → Run workflow**, select `main`, enable `publish`, and enter `3.5.0`. Review the exact validated commit and approve the `release` environment when requested. A push or an ordinary validation run does not publish a release.
7. Verify that `v3.5.0` resolves to that run's source commit and that its five release assets are the two installable ZIPs, `RELEASE_NOTES.md`, `release.json` and `SHA256SUMS`. Verify the hashes and the public download links before announcing the release.

If publication is interrupted, rerun the failed publication job for the same source commit. The publisher discovers matching drafts, including those whose tag has not yet been created, verifies their existing assets and resumes missing uploads. Multiple releases claiming the same tag stop publication for review. Do not create a replacement tag, delete a published release or upload a separately rebuilt package to work around a mismatch.

References: [GitHub environment configuration](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments), [manual workflow runs](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow), and [release lookup API](https://docs.github.com/en/rest/releases/releases#get-a-release-by-tag-name).
