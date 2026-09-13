#!/usr/bin/env python3
"""Package the optional sender from the same reviewed scanner/transport sources."""
import argparse
from pathlib import Path
import re
import zipfile

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
        "## Title: Ąlpha Şquad Build Share", "## Author: SeRuM1",
        f"## Version: {version}", f"## AddOnVersion: {addon_version}", f"## APIVersion: {api}",
        "## DependsOn: LibGroupBroadcast", "## OptionalDependsOn: AlphaSquadUI LibFoodDrinkBuff",
        "## SavedVariables: AlphaSquadBuildShareSavedVariables", "",
        "Bootstrap.lua", *["Shared/" + name for name in FILES], "Runtime.lua", "",
    ]
    destination = Path(destination).resolve()
    destination.parent.mkdir(parents=True, exist_ok=True)
    prefix = "AlphaSquadBuildShare/"
    with zipfile.ZipFile(destination, "w", zipfile.ZIP_DEFLATED) as archive:
        archive.writestr(prefix + "AlphaSquadBuildShare.txt", "\n".join(metadata))
        for name in ("Bootstrap.lua", "Runtime.lua"):
            archive.writestr(prefix + name, (ROOT / "companion" / name).read_bytes())
        for name in FILES:
            # A lexical host keeps this sender separate from the full addon's
            # global namespace while retaining byte-identical shared source.
            content = "if AlphaSquadBuildShare.disabled then return end\nlocal AlphaSquadUI = AlphaSquadBuildShare.Host\n"
            content += (ROOT / "AlphaSquadUI/Modules/SupportCoverage" / name).read_text()
            archive.writestr(prefix + "Shared/" + name, content)
    with zipfile.ZipFile(destination) as archive:
        assert archive.testzip() is None
        assert len(archive.namelist()) == len(FILES) + 3
    print(destination)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", help="Destination ZIP path")
    build(parser.parse_args().output)
