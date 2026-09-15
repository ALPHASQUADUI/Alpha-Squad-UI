"""Deterministic ZIP creation and strict release-package integrity checks."""
import hashlib
from pathlib import Path, PurePosixPath
import re
import stat
import zipfile


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
        return {name: archive.read(name) for name in names}


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()
