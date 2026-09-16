"""Deterministic ZIP creation and strict release-package integrity checks."""
import hashlib
from pathlib import Path, PurePosixPath
import re
import stat
import zipfile

from security_scan import findings


# Assets enter packages only after an explicit code review. Runtime entries are
# taken from each package's own manifest; no directory-wide wildcard is shipped.
REVIEWED_ASSETS = {
    "AlphaSquadUI": {"LICENSE", "Modules/ULTTracker/README.md",
                     "Modules/SupportCoverage/README.md", "Modules/Overload/README.md"},
    "AlphaSquadBuildShare": {"LICENSE"},
}
FORBIDDEN_PARTS = {".git", "savedvariables", "logs", "errors", "__pycache__", "credentials"}


def allowed_member(name):
    parts = PurePosixPath(name).parts
    return (bool(parts) and PurePosixPath(name).as_posix() == name
            and not name.startswith("/") and "\\" not in name
            and not any(part in {".", ".."} or part.lower() in FORBIDDEN_PARTS
                        or part.startswith(".") for part in parts)
            and not name.lower().endswith((".bak", ".old", ".tmp", ".log", ".swp", "~")))


def validate_payloads(members, package):
    """Enforce the release allowlist and scan the exact bytes being shipped."""
    if package not in REVIEWED_ASSETS:
        raise ValueError("Unknown release package")
    manifest_name = f"{package}/{package}.txt"
    if manifest_name not in members:
        raise ValueError("Package manifest is missing")
    manifest = members[manifest_name].decode("utf-8")
    runtime = [line.strip() for line in manifest.splitlines()
               if line.strip() and not line.startswith("##")]
    if len(runtime) != len(set(runtime)):
        raise ValueError("Duplicate manifest entry")
    for name in runtime:
        if not allowed_member(name) or PurePosixPath(name).suffix not in {".lua", ".xml"}:
            raise ValueError("Manifest contains an unsafe or unsupported runtime entry")
    required = {manifest_name, *(f"{package}/{name}" for name in runtime), f"{package}/LICENSE"}
    allowed = required | {f"{package}/{name}" for name in REVIEWED_ASSETS[package]}
    if not required.issubset(members) or not set(members).issubset(allowed):
        raise ValueError("Package contains unexpected or missing files")
    if len({name.casefold() for name in members}) != len(members):
        raise ValueError("Package contains ambiguous case-insensitive paths")
    for name, data in members.items():
        if not allowed_member(name):
            raise ValueError("Package contains an unsafe member")
        if findings(name.encode()) or findings(data):
            raise ValueError("Package security/privacy scan failed (matching values redacted)")


def collect_package(root, package, license_path):
    """Reject unexpected local files even when Git would ignore them."""
    root = Path(root)
    members = {}
    for path in sorted(root.rglob("*")):
        if path.is_symlink():
            raise ValueError("Symlinks are not packageable")
        if path.is_file() and path.relative_to(root).as_posix() != "Media/.gitkeep":
            members[f"{package}/{path.relative_to(root).as_posix()}"] = path.read_bytes()
    members[f"{package}/LICENSE"] = Path(license_path).read_bytes()
    validate_payloads(members, package)
    return members


def version_numbers(version):
    match = re.fullmatch(r"(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)", version)
    if not match:
        raise ValueError("Version must use numeric major.minor.patch")
    major, minor, patch = map(int, match.groups())
    if minor >= 100 or patch >= 100:
        raise ValueError("Minor and patch must fit the ESO AddOnVersion encoding")
    return major * 10000 + minor * 100 + patch


def write_archive(destination, members):
    destination = Path(destination)
    destination.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(destination, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in sorted(members.items()):
            info = zipfile.ZipInfo(name, (1980, 1, 1, 0, 0, 0))
            info.create_system = 3
            info.external_attr = (stat.S_IFREG | 0o644) << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(info, data, compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)


def inspect_archive(path, package):
    """Reject ambiguous/unsafe members before extraction; return exact payloads."""
    with zipfile.ZipFile(path) as archive:
        if archive.testzip() is not None:
            raise ValueError("ZIP integrity check failed")
        names = archive.namelist()
        if len(names) != len(set(names)):
            raise ValueError("ZIP contains duplicate members")
        for info in archive.infolist():
            name = info.filename
            parts = PurePosixPath(name).parts
            if (not parts or parts[0] != package or ".." in parts or "\\" in name
                    or name.startswith("/") or name.endswith("/")
                    or stat.S_ISLNK(info.external_attr >> 16)):
                raise ValueError("ZIP contains an unsafe member")
        if f"{package}/{package}.txt" not in names:
            raise ValueError("Package manifest is missing")
        payloads = {name: archive.read(name) for name in names}
        validate_payloads(payloads, package)
        return payloads


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()
