#!/usr/bin/env python3
"""Package the optional sender from the same reviewed scanner/transport sources."""
import argparse
from pathlib import Path
import re
import zipfile

from package_utils import inspect_archive, validate_payloads, write_archive

ROOT = Path(__file__).resolve().parents[1]
FILES = [
    "SupportCoverageCatalog.lua", "SupportCoverageScanner.lua", "SupportCoverageBuild.lua",
    "SupportCoverageSources.lua", "SupportCoverageBuildCodec.lua", "SupportCoverageShare.lua",
    "SupportCoverageDetails.lua",
]

def build(destination):
    manifest = (ROOT / "AlphaSquadUI/AlphaSquadUI.txt").read_text()
    version = re.search(r"^## Version: (.+)$", manifest, re.M).group(1)
    addon_version = re.search(r"^## AddOnVersion: (.+)$", manifest, re.M).group(1)
    api = re.search(r"^## APIVersion: (.+)$", manifest, re.M).group(1)
    metadata = [
        "## Title: Ąlpha Şquad Build Share", "## Author: @SeRuM1",
        f"## Version: {version}", f"## AddOnVersion: {addon_version}", f"## APIVersion: {api}",
        "## DependsOn: LibGroupBroadcast", "## OptionalDependsOn: AlphaSquadUI LibFoodDrinkBuff",
        "## SavedVariables: AlphaSquadBuildShareSavedVariables", "",
        "Bootstrap.lua", "Shared/Sharing.lua", *["Shared/" + name for name in FILES], "Runtime.lua", "",
    ]
    destination = Path(destination).resolve()
    destination.parent.mkdir(parents=True, exist_ok=True)
    prefix = "AlphaSquadBuildShare/"
    members = {prefix + "AlphaSquadBuildShare.txt": "\n".join(metadata).encode()}
    for name in ("Bootstrap.lua", "Runtime.lua"):
        members[prefix + name] = (ROOT / "companion" / name).read_bytes()
    for name in ["Sharing.lua", *FILES]:
        # A lexical host keeps this sender separate from the full addon's
        # global namespace while retaining byte-identical shared source.
        content = "if AlphaSquadBuildShare.disabled then return end\nlocal AlphaSquadUI = AlphaSquadBuildShare.Host\n"
        source = ROOT / "AlphaSquadUI" / ("Core" if name == "Sharing.lua" else "Modules/SupportCoverage") / name
        content += source.read_text()
        members[prefix + "Shared/" + name] = content.encode()
    if (ROOT / "LICENSE").is_file():
        members[prefix + "LICENSE"] = (ROOT / "LICENSE").read_bytes()
    validate_payloads(members, "AlphaSquadBuildShare")
    write_archive(destination, members)
    assert inspect_archive(destination, "AlphaSquadBuildShare") == members
    print(destination)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", help="Destination ZIP path")
    build(parser.parse_args().output)
