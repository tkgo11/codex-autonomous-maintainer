#!/usr/bin/env python3
"""Validate that CHECKSUMS.txt exactly covers the tracked package."""

from __future__ import annotations

import argparse
import hashlib
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "CHECKSUMS.txt"
SELF = "CHECKSUMS.txt"
LINE_RE = re.compile(r"^([0-9a-f]{64})  \./(.+)$")


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def tracked_paths() -> list[str]:
    try:
        result = subprocess.run(
            ["git", "ls-files", "-z"],
            cwd=ROOT,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except (OSError, subprocess.CalledProcessError) as exc:
        fail(f"cannot enumerate tracked files: {exc}")

    paths = [
        item.decode("utf-8")
        for item in result.stdout.split(b"\0")
        if item and item.decode("utf-8") != SELF
    ]
    paths.sort()

    for rel in paths:
        path = ROOT / rel
        if path.is_symlink():
            fail(f"tracked symbolic links are not supported by the package manifest: {rel}")
        if not path.is_file():
            fail(f"tracked path is not a regular file: {rel}")
    return paths


def digest(path: Path) -> str:
    hasher = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            hasher.update(chunk)
    return hasher.hexdigest()


def render(paths: list[str]) -> str:
    return "".join(f"{digest(ROOT / rel)}  ./{rel}\n" for rel in paths)


def check(paths: list[str]) -> None:
    try:
        lines = MANIFEST.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        fail(f"cannot read {MANIFEST}: {exc}")

    entries: dict[str, str] = {}
    order: list[str] = []
    for number, line in enumerate(lines, start=1):
        match = LINE_RE.fullmatch(line)
        if not match:
            fail(f"malformed checksum line {number}: {line!r}")
        expected, rel = match.groups()
        if rel in entries:
            fail(f"duplicate checksum entry: {rel}")
        if rel == SELF:
            fail("CHECKSUMS.txt must not checksum itself")
        entries[rel] = expected
        order.append(rel)

    if order != sorted(order):
        fail("CHECKSUMS.txt entries must be sorted by path")

    tracked = set(paths)
    listed = set(entries)
    missing = sorted(tracked - listed)
    extra = sorted(listed - tracked)
    if missing:
        fail("tracked files missing from CHECKSUMS.txt: " + ", ".join(missing))
    if extra:
        fail("stale checksum entries: " + ", ".join(extra))

    mismatches = [
        rel for rel in paths if digest(ROOT / rel) != entries[rel]
    ]
    if mismatches:
        fail("checksum mismatch: " + ", ".join(mismatches))

    print(f"ok: CHECKSUMS.txt covers {len(paths)} tracked files")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--write",
        action="store_true",
        help="regenerate CHECKSUMS.txt from the tracked working tree",
    )
    args = parser.parse_args()

    paths = tracked_paths()
    if args.write:
        MANIFEST.write_text(render(paths), encoding="utf-8", newline="\n")
        print(f"wrote: {MANIFEST} ({len(paths)} files)")
    else:
        check(paths)


if __name__ == "__main__":
    main()
