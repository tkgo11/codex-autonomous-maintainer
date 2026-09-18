#!/usr/bin/env python3
"""Validate that VERSION, CHANGELOG.md, and README.md agree on the current version."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERSION_RE = re.compile(r"^\d+\.\d+\.\d+$")


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--root",
        default=str(ROOT),
        help="repository root containing VERSION, CHANGELOG.md, and README.md",
    )
    args = parser.parse_args()
    root = Path(args.root).resolve()

    version_file = root / "VERSION"
    changelog = root / "CHANGELOG.md"
    readme = root / "README.md"
    for path in (version_file, changelog, readme):
        if not path.is_file():
            fail(f"missing required release file: {path}")

    version = version_file.read_text(encoding="utf-8").strip()
    if not VERSION_RE.fullmatch(version):
        fail(f"VERSION must be a bare X.Y.Z version, got {version!r}")

    headings = re.findall(
        r"(?m)^## (\d+\.\d+\.\d+)\b", changelog.read_text(encoding="utf-8")
    )
    if not headings:
        fail("CHANGELOG.md has no '## X.Y.Z' release heading")
    if headings[0] != version:
        fail(
            f"VERSION {version} does not match latest CHANGELOG.md "
            f"heading {headings[0]}"
        )

    readme_match = re.search(
        r"Current version: \*\*(\d+\.\d+\.\d+)\*\*",
        readme.read_text(encoding="utf-8"),
    )
    if not readme_match:
        fail("README.md is missing 'Current version: **X.Y.Z**'")
    if readme_match.group(1) != version:
        fail(
            f"VERSION {version} does not match README.md version "
            f"{readme_match.group(1)}"
        )

    print(f"ok: release version {version} consistent across VERSION, CHANGELOG.md, README.md")


if __name__ == "__main__":
    main()
