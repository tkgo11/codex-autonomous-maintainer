#!/usr/bin/env python3
"""Dependency-free structural validation for autonomous-maintainer/SKILL.md."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

EXPECTED_NAME = "autonomous-maintainer"
EXPECTED_SECTIONS = list(range(1, 31))
REQUIRED_OPTIONS = {
    "mode",
    "focus",
    "feature_policy",
    "resume",
    "commit",
    "max_epochs",
    "quiescence_scans",
    "parallelism",
    "network",
}


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def parse_frontmatter(text: str) -> dict[str, str]:
    lines = text.splitlines()
    if not lines or lines[0] != "---":
        fail("the first line must be the YAML frontmatter delimiter '---'")

    try:
        end = lines.index("---", 1)
    except ValueError:
        fail("missing closing YAML frontmatter delimiter")

    result: dict[str, str] = {}
    for line_no, line in enumerate(lines[1:end], start=2):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        match = re.fullmatch(r"([A-Za-z0-9_-]+):\s*(.*)", line)
        if not match:
            fail(f"unsupported or malformed frontmatter at line {line_no}: {line!r}")
        key, value = match.groups()
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
            value = value[1:-1]
        if key in result:
            fail(f"duplicate frontmatter key: {key}")
        result[key] = value
    return result


def validate(path: Path) -> None:
    try:
        raw = path.read_bytes()
    except OSError as exc:
        fail(f"cannot read {path}: {exc}")

    if raw.startswith(b"\xef\xbb\xbf"):
        fail("UTF-8 BOM is not allowed before frontmatter")

    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError as exc:
        fail(f"file is not valid UTF-8: {exc}")

    if "\r\n" in text:
        fail("use LF line endings")

    frontmatter = parse_frontmatter(text)
    if frontmatter.get("name") != EXPECTED_NAME:
        fail(f"frontmatter name must be {EXPECTED_NAME!r}")
    if not frontmatter.get("description", "").strip():
        fail("frontmatter description must not be empty")

    title_count = len(re.findall(r"(?m)^# Autonomous Maintainer\s*$", text))
    if title_count != 1:
        fail("expected exactly one '# Autonomous Maintainer' title")

    section_numbers = [
        int(number)
        for number in re.findall(r"(?m)^##\s+(\d+)\.\s+", text)
    ]
    if section_numbers != EXPECTED_SECTIONS:
        fail(
            "numbered level-2 sections must be exactly 1 through 30 in order; "
            f"found {section_numbers}"
        )

    fence_count = len(re.findall(r"(?m)^```", text))
    if fence_count % 2 != 0:
        fail(f"unbalanced fenced code blocks: found {fence_count} delimiters")

    invocation_match = re.search(
        r"(?ms)^## 3\. Invocation Contract\s*(.*?)(?=^## 4\.)", text
    )
    if not invocation_match:
        fail("missing Invocation Contract section")
    invocation = invocation_match.group(1)
    missing_options = sorted(
        option for option in REQUIRED_OPTIONS if f"`{option}`" not in invocation
    )
    if missing_options:
        fail(f"Invocation Contract is missing options: {', '.join(missing_options)}")

    required_phrases = [
        "Do not invoke `$autopilot` inside this skill.",
        "Do not invoke `$ralph` inside this skill.",
        "Do not invoke `$security-review`",
        "Never claim",
        "quiescence_scans",
        "max_epochs",
        "blocked-user-work",
        "resume-required",
    ]
    missing_phrases = [phrase for phrase in required_phrases if phrase not in text]
    if missing_phrases:
        fail("missing required safeguards: " + "; ".join(missing_phrases))

    placeholder_patterns = [
        r"\[Describe ",
        r"\[Specific action",
        r"(?m)^\s*(?:TODO|TBD)(?:[:\s]|$)",
    ]
    if any(re.search(pattern, text) for pattern in placeholder_patterns):
        fail("unresolved template placeholder found")

    print(f"ok: {path} ({len(text.splitlines())} lines, {len(raw)} bytes)")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("path", nargs="?", default="SKILL.md")
    args = parser.parse_args()
    validate(Path(args.path))


if __name__ == "__main__":
    main()
