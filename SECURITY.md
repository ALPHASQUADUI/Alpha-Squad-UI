# Security policy

## Supported versions

Security fixes target the latest published Alpha Squad UI release and its matching Build Share companion. Update both packages before reproducing an issue. Older releases may be affected even when their interfaces appear unchanged.

## Report a vulnerability privately

Use **Security → Report a vulnerability** on this repository when that option is available. Otherwise, contact **@SeRuM1** privately through the [Alpha Squad community](https://discord.gg/snDyd23h6N) to arrange a private report. Do not post exploit details or credentials in a public issue or community channel.

Include the addon and library versions, the affected feature, minimal reproduction steps, and the expected and actual result. Describe whether another group member, a modified sender, a malformed packet or a local action is required. A small synthetic example is preferable to a real player capture.

Remove real names, email addresses, private chats, account identifiers unrelated to the reproduction, access tokens and player build data from screenshots and attachments. Do not upload full SavedVariables or packet captures publicly. Never send a password or access token to reproduce an addon issue.

Reports are assessed for impact, affected versions and a reproducible fix. Response times depend on maintainer availability; no response deadline is promised. Coordinate disclosure after a fix or mitigation is available.

## Data boundaries

Build sharing uses ESO's group channel, not the website or Discord. Group recipients can observe broadcasts; targeted requests are not encryption. An item or skill claim can be checked for consistency but cannot prove what a modified sender really wears. A checksum detects corruption, not dishonesty.

Remote builds are temporary in-memory snapshots. Received packets cannot supply executable Lua, external URLs or arbitrary texture paths. Sharing permissions and module tracking are separate. See the [data security review](docs/SECURITY_REVIEW.md) for limits, validation and consent behavior.

Fresh installations start sharing OFF and require an explicit choice. Existing saved preferences are preserved. A queued-data revocation failure is reported; if native controls have been blocked for safety, re-enabling requires an explicit choice after the problem is resolved. Data already delivered to group members cannot be recalled.

Transport IDs 507/510 remain provisional. Public protocol reservation and coexistence validation have not been established by the automated checks. Do not describe this transport as certified or independently authenticated.

## Project and dependency security

Use an approved public commit identity. The maintainer prefers the public project mailbox `info@alphasquadeso.com` with an approved public alias and also permits the matching GitHub-provided `noreply` identity, including automatic connector attribution. A `noreply` email is not mandatory; the project-mailbox approval covers only that exact address. Keep credentials and real player captures out of the repository and use the redacted security checks before publication. Report a discovered historical exposure privately; do not repeat its value in an issue or commit message.

Third-party libraries and ESO itself have their own security and compatibility boundaries. Problems in those components should also be reported to their maintainers through their published security or support routes.
