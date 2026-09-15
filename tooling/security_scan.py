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
    if address.lower() == 'noreply@github.com':
        return True
    domain = address.rsplit("@", 1)[-1].lower()
    if domain == "users.noreply.github.com":
        return True
    # Only synthetic content examples may use reserved documentation domains.
    return not metadata and (domain in {"example.com", "example.org", "example.net"}
                             or domain.endswith((".invalid", ".test", ".example")))


def findings(data):
    text = data.decode("utf-8", errors="replace")
    result = []
    for label, pattern in RULES.items():
        for match in pattern.finditer(text):
            result.append((text.count("\n", 0, match.start()) + 1, label))
    for match in EMAIL.finditer(text):
        if not public_email(match.group()):
            result.append((text.count("\n", 0, match.start()) + 1, "non-public email"))
    return result


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


def scan(root=ROOT, base=None, head="HEAD"):
    problems = set()

    def inspect(label, content):
        for line, rule in findings(content):
            # Paths and rule names are sufficient; never emit the matching data.
            problems.add(f"{label}:{line}: {rule}")

    names = git("ls-files", "-z", "--cached", "--others", "--exclude-standard", root=root)
    for name in set(filter(None, names.decode().split("\0"))):
        path = root / name
        if path.is_symlink():
            problems.add(f"{name}: symbolic link is not allowed in the repository")
        elif path.is_file():
            inspect(name, path.read_bytes())
    # New-branch/dispatch/local checks enforce HEAD without reopening known
    # historical incidents. Existing pushes and PRs scan every new commit,
    # including a credential introduced then deleted within that same range.
    commits = (git("rev-list", f"{base}..{head}", root=root).decode().splitlines()
               if base else [git("rev-parse", "--verify", f"{head}^{{commit}}", root=root).decode().strip()])
    seen_blobs = set()
    for commit in commits:
        fields = git("show", "-s", "--format=%ae%x00%ce%x00%B", commit, root=root).decode().split("\0", 2)
        for role, address in zip(("author", "committer"), fields[:2]):
            if not public_email(address.strip(), metadata=True):
                problems.add(f"commit {commit[:12]}: {role} must use a GitHub noreply email")
        inspect(f"commit {commit[:12]} message", fields[2].encode())
        # Compare merge commits to each parent as well as ordinary commits.
        changed = git("diff-tree", "--root", "-m", "--no-commit-id", "--name-only", "--diff-filter=ACMRT", "-r", "-z", commit, root=root)
        for name in set(filter(None, changed.decode().split("\0"))):
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
    args = parser.parse_args()
    problems = scan(base=args.base, head=args.head)
    if problems:
        print("Security/privacy checks failed (matching values are redacted):", file=sys.stderr)
        print("\n".join(problems), file=sys.stderr)
        return 1
    print("Security/privacy patterns: current files and proposed commits passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
