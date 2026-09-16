#!/usr/bin/env python3
"""Fail on recognizable secrets/private email without printing their contents.

This bounded pattern check complements GitHub secret scanning; it is not proof
that a repository contains no confidential data. Historical remediation remains
separate: only newly proposed commits and the current tree are enforced here.
"""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
# Names are intentionally public aliases, never civil names. A matching alias
# and approved email are necessary, but GitHub account ownership still requires
# review before publication; an allowlisted address is not authentication.
PUBLIC_IDENTITIES = {
    "SeRuM1": {"adi684"}, "adi684": {"adi684"},
    "GitHub": {None},
    "github-actions[bot]": {"github-actions[bot]"},
    "dependabot[bot]": {"dependabot[bot]"},
}
# Explicitly approved public project mailbox; no domain-wide allowance.
PUBLIC_PROJECT_EMAILS = {"info@alphasquadeso.com": {"SeRuM1", "adi684"}}
# This public service trailer is an exception only in approved bot commit
# messages. Keep the address out of the global email policy and file scanner.
DEPENDABOT_SIGNOFF = "Signed-off-by: dependabot[bot] <" + "support" + "@" + "github.com>"
EMAIL = re.compile(r"(?<![\w.+-])[A-Za-z0-9][A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]*@[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?\.[A-Za-z]{2,}(?![\w.-])")
RULES = {
    "private key": re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----"),
    "GitHub credential": re.compile(r"\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,})\b"),
    "cloud access key": re.compile(r"\b(?:AKIA|ASIA)[A-Z0-9]{16}\b"),
    "Slack credential": re.compile(r"\bxox[baprs]-[A-Za-z0-9-]{20,}\b"),
    "service credential": re.compile(r"\b(?:sk_live_|rk_live_)[A-Za-z0-9]{20,}\b"),
    "credential in URL": re.compile(r"https?://[^\s/@:]+:[^\s/@]+@[^\s/]+"),
}


def git(*arguments, root=ROOT):
    return subprocess.run(["git", *arguments], cwd=root, check=True,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout


def public_email(address, metadata=False):
    if address in PUBLIC_PROJECT_EMAILS:
        return True
    if address.lower() == 'noreply@github.com':
        return True
    domain = address.rsplit("@", 1)[-1].lower()
    if domain == "users.noreply.github.com":
        return True
    # Only synthetic content examples may use reserved documentation domains.
    return not metadata and (domain in {"example.com", "example.org", "example.net"}
                             or domain.endswith((".invalid", ".test", ".example")))


def approved_identity(name, address, identities=None):
    identities = PUBLIC_IDENTITIES if identities is None else identities
    if name not in identities or not public_email(address, metadata=True):
        return False
    if address in PUBLIC_PROJECT_EMAILS:
        return name in PUBLIC_PROJECT_EMAILS[address]
    login = None if address.lower() == "noreply@github.com" else address.rsplit("@", 1)[0]
    if login and "+" in login:
        number, login = login.split("+", 1)
        if not number.isdigit():
            return False
    return login in identities[name]


def findings(data, private_terms=()):
    text = data.decode("utf-8", errors="replace")
    result = []
    for label, pattern in RULES.items():
        for match in pattern.finditer(text):
            result.append((text.count("\n", 0, match.start()) + 1, label))
    for match in EMAIL.finditer(text):
        if not public_email(match.group()):
            result.append((text.count("\n", 0, match.start()) + 1, "non-public email"))
    for term in private_terms:
        for match in re.finditer(re.escape(term), text, re.I):
            result.append((text.count("\n", 0, match.start()) + 1, "private term"))
    return result


def commit_message_findings(data, metadata, private_terms=(), identities=None):
    """Exempt one exact service trailer; preserve every other privacy finding."""
    result = findings(data, private_terms)
    if (len(metadata) < 2 or metadata[0][0] != "dependabot[bot]"
            or not all(approved_identity(name, address, identities) for name, address in metadata)):
        return result
    # Match findings()'s LF line numbering exactly, even with unusual controls.
    lines = data.decode("utf-8", errors="replace").split("\n")
    if lines.count(DEPENDABOT_SIGNOFF) != 1:
        return result
    # Only an exact final trailer line is accepted, never a quoted body excerpt
    # or a broader mailbox/domain exception. Secrets and private terms still run
    # on the original complete message, including this line.
    final_line = next((index + 1 for index in range(len(lines) - 1, -1, -1) if lines[index].strip()), None)
    if final_line is None or lines[final_line - 1] != DEPENDABOT_SIGNOFF:
        return result
    return [(line, rule) for line, rule in result
            if not (line == final_line and rule == "non-public email")]


def incoming_commits(root, base, head):
    if base:
        return git("rev-list", f"{base}..{head}", root=root).decode().splitlines()
    # First-branch pushes have an all-zero `before`. Compare their complete new
    # history to main, without reopening pre-existing historical incidents.
    for reference in ("refs/remotes/origin/main", "refs/heads/main"):
        try:
            baseline = git("merge-base", reference, head, root=root).decode().strip()
        except subprocess.CalledProcessError:
            continue
        commits = git("rev-list", f"{baseline}..{head}", root=root).decode().splitlines()
        return commits or [git("rev-parse", "--verify", f"{head}^{{commit}}", root=root).decode().strip()]
    return [git("rev-parse", "--verify", f"{head}^{{commit}}", root=root).decode().strip()]


def event_range():
    path = os.environ.get("GITHUB_EVENT_PATH")
    if not path:
        return None, "HEAD"
    event = json.loads(Path(path).read_text())
    if os.environ.get("GITHUB_EVENT_NAME") == "pull_request":
        return event["pull_request"]["base"]["sha"], event["pull_request"]["head"]["sha"]
    if os.environ.get("GITHUB_EVENT_NAME") == "push":
        base = event.get("before", "")
        return (base if base.strip("0") else None), event["after"]
    return None, "HEAD"


def scan(root=ROOT, base=None, head="HEAD", private_terms=(), identities=None):
    problems = set()

    def inspect(label, content, metadata=None):
        matches = (findings(content, private_terms) if metadata is None else
                   commit_message_findings(content, metadata, private_terms, identities))
        for line, rule in matches:
            # Paths and rule names are sufficient; never emit the matching data.
            safe_label = "[REDACTED PATH]" if findings(label.encode(), private_terms) else label
            problems.add(f"{safe_label!r}:{line}: {rule}")

    names = git("ls-files", "-z", "--cached", "--others", "--exclude-standard", root=root)
    for name in set(filter(None, names.decode().split("\0"))):
        path = root / name
        inspect("repository path", name.encode())
        if path.is_symlink():
            problems.add("Repository contains a symbolic link")
        elif path.is_file():
            inspect(name, path.read_bytes())
    commits = incoming_commits(root, base, head)
    seen_blobs = set()
    for commit in commits:
        fields = git("show", "-s", "--format=%an%x00%ae%x00%cn%x00%ce%x00%B", commit, root=root).decode().split("\0", 4)
        identities_to_check = [("author", fields[0], fields[1]), ("committer", fields[2], fields[3])]
        for line in fields[4].splitlines():
            if line.lower().startswith("co-authored-by:"):
                match = re.fullmatch(r"Co-authored-by:\s*(.+?)\s*<([^<>]+)>\s*", line, re.I)
                if not match:
                    problems.add(f"commit {commit[:12]}: invalid co-author metadata")
                else:
                    identities_to_check.append(("co-author", match[1], match[2]))
        for role, name, address in identities_to_check:
            if not approved_identity(name.strip(), address.strip(), identities):
                problems.add(f"commit {commit[:12]}: {role} must use an approved public identity")
        inspect(f"commit {commit[:12]} message", fields[4].encode(),
                [(name, address) for _, name, address in identities_to_check])
        # Compare merge commits to each parent as well as ordinary commits.
        changed = git("diff-tree", "--root", "-m", "--no-commit-id", "--name-only", "--diff-filter=ACMRT", "-r", "-z", commit, root=root)
        for name in set(filter(None, changed.decode().split("\0"))):
            inspect(f"commit {commit[:12]} path", name.encode())
            blob = git("rev-parse", f"{commit}:{name}", root=root).strip()
            if blob not in seen_blobs:
                seen_blobs.add(blob)
                inspect(f"commit {commit[:12]} {name}", git("show", f"{commit}:{name}", root=root))
    return sorted(problems)


def main():
    base, head = event_range()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", default=base)
    parser.add_argument("--head", default=head)
    parser.add_argument("--private-terms-file", type=Path,
                        help="Optional local JSON list of private terms; never commit this file")
    args = parser.parse_args()
    terms = ()
    if args.private_terms_file:
        try:
            terms = json.loads(args.private_terms_file.read_text())
            if not isinstance(terms, list) or any(not isinstance(term, str) or len(term) < 4 for term in terms):
                raise ValueError()
        except (OSError, ValueError):
            print("Private terms must be a local JSON list of strings of at least four characters.", file=sys.stderr)
            return 1
    problems = scan(base=args.base, head=args.head, private_terms=terms)
    if problems:
        print("Security/privacy checks failed (matching values are redacted):", file=sys.stderr)
        print("\n".join(problems), file=sys.stderr)
        return 1
    print("Security/privacy patterns: current files and proposed commits passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
