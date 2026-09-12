#!/usr/bin/env python3
"""Dependency-free structural validation for both maintained skill variants."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

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
    "candidate_retry_limit",
    "rewrite_policy",
    "compatibility",
    "delivery",
    "pr_state",
}

COMMON_REQUIRED = [
    "Never claim",
    "feature_policy=proactive",
    "| `feature_policy` | `off`, `documented`, `strong-evidence`, `proactive` | `proactive` |",
    "quiescence_scans",
    "max_epochs",
    "rewrite_policy=aggressive",
    "compatibility=observable-output",
    "delivery=pull-request",
    "observable-output",
    "pull request",
    "blocked-user-work",
    "resume-required",
    "awaiting-user-pr-approval",
    "explicit user approval",
]

SKILL_SPECS = {
    "autonomous-maintainer": {
        "title": "Autonomous Maintainer",
        "sections": list(range(1, 31)),
        "max_lines": 1000,
        "required_phrases": [
            "Do not invoke `$autopilot` inside this skill.",
            "Do not invoke `$ralph` inside this skill.",
            "Do not invoke `$security-review`",
            "Never merge the PR automatically.",
        ],
        "forbidden_patterns": [],
    },
    "autonomous-maintainer-standalone": {
        "title": "Autonomous Maintainer Standalone",
        "sections": list(range(1, 25)),
        "max_lines": 500,
        "required_phrases": [
            "external orchestration framework",
            ".autonomous-maintainer/",
            "review_kind=self",
            "independent read-only review",
            "Never merge it automatically.",
        ],
        "forbidden_patterns": [
            r"(?i)\bomx\b",
            r"(?i)ultragoal",
            r"\$team\b",
            r"\$code-review\b",
            r"\$ultraqa\b",
            r"\$ralplan\b",
            r"\$autopilot\b",
            r"\$ralph\b",
            r"\.omx/",
        ],
    },
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



def validate_openai_metadata(skill_path: Path, skill_name: str) -> None:
    skill_dir = skill_path.parent
    metadata_path = skill_dir / "agents" / "openai.yaml"
    try:
        raw = metadata_path.read_bytes()
    except OSError as exc:
        fail(f"missing or unreadable Codex metadata {metadata_path}: {exc}")

    if raw.startswith(b"\xef\xbb\xbf"):
        fail(f"{metadata_path}: UTF-8 BOM is not allowed")
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError as exc:
        fail(f"{metadata_path}: not valid UTF-8: {exc}")
    if "\r\n" in text:
        fail(f"{metadata_path}: use LF line endings")
    if "\t" in text:
        fail(f"{metadata_path}: tabs are not allowed")

    if not re.search(r"(?m)^interface:\s*$", text):
        fail(f"{metadata_path}: missing interface mapping")

    def quoted_scalar(key: str) -> str:
        matches = re.findall(
            rf'(?m)^\s{{2}}{re.escape(key)}:\s*"([^"\n]*)"\s*    try:
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
    unexpected_keys = sorted(set(frontmatter) - {"name", "description"})
    if unexpected_keys:
        fail("unsupported frontmatter keys: " + ", ".join(unexpected_keys))
    name = frontmatter.get("name", "")
    if name not in SKILL_SPECS:
        fail("unknown skill name")
    if not frontmatter.get("description", "").strip():
        fail("frontmatter description must not be empty")

    spec = SKILL_SPECS[name]
    title = spec["title"]
    if len(re.findall(rf"(?m)^# {re.escape(title)}\s*$", text)) != 1:
        fail(f"expected exactly one '# {title}' title")

    section_numbers = [
        int(number) for number in re.findall(r"(?m)^##\s+(\d+)\.\s+", text)
    ]
    if section_numbers != spec["sections"]:
        fail(f"numbered sections do not match contract: {section_numbers}")

    line_count = len(text.splitlines())
    if line_count > spec["max_lines"]:
        fail(f"{name} exceeds {spec['max_lines']} lines: {line_count}")
    if len(re.findall(r"(?m)^```", text)) % 2:
        fail("unbalanced fenced code blocks")

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
        fail("Invocation Contract is missing options: " + ", ".join(missing_options))

    required = [*COMMON_REQUIRED, *spec["required_phrases"]]
    missing_phrases = [phrase for phrase in required if phrase not in text]
    if missing_phrases:
        fail("missing required safeguards: " + "; ".join(missing_phrases))

    forbidden = [
        pattern for pattern in spec["forbidden_patterns"] if re.search(pattern, text)
    ]
    if forbidden:
        fail("forbidden standalone dependencies found: " + "; ".join(forbidden))

    if any(
        re.search(pattern, text)
        for pattern in [r"\[Describe ", r"\[Specific action", r"(?m)^\s*(?:TODO|TBD)(?:[:\s]|$)"]
    ):
        fail("unresolved template placeholder found")

    validate_openai_metadata(path, name)\n\n    print(f"ok: {path} ({line_count} lines, {len(raw)} bytes, metadata ok)")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("path", nargs="?", default="SKILL.md")
    args = parser.parse_args()
    validate(Path(args.path))


if __name__ == "__main__":
    main()
,
            text,
        )
        if len(matches) != 1:
            fail(f"{metadata_path}: expected one quoted {key} value")
        return matches[0]

    display_name = quoted_scalar("display_name")
    short_description = quoted_scalar("short_description")
    icon_small = quoted_scalar("icon_small")
    icon_large = quoted_scalar("icon_large")
    default_prompt = quoted_scalar("default_prompt")

    if not display_name.strip():
        fail(f"{metadata_path}: display_name must not be empty")
    if not 25 <= len(short_description) <= 64:
        fail(
            f"{metadata_path}: short_description must be 25..64 characters "
            f"(got {len(short_description)})"
        )
    if f"$" + skill_name not in default_prompt:
        fail(
            f"{metadata_path}: default_prompt must explicitly reference "
            f"$" + skill_name
        )

    for key, value in (("icon_small", icon_small), ("icon_large", icon_large)):
        if not value.startswith("./assets/") or ".." in Path(value).parts:
            fail(f"{metadata_path}: {key} must be a safe ./assets/... path")
        asset_path = skill_dir / value[2:]
        if asset_path.is_symlink() or not asset_path.is_file():
            fail(f"{metadata_path}: referenced asset does not exist: {value}")
        if asset_path.suffix.lower() == ".svg":
            try:
                asset_text = asset_path.read_text(encoding="utf-8")
            except (OSError, UnicodeDecodeError) as exc:
                fail(f"{asset_path}: unreadable SVG: {exc}")
            if "<svg" not in asset_text or "</svg>" not in asset_text:
                fail(f"{asset_path}: malformed SVG asset")

    policy_match = re.findall(
        r"(?m)^\s{2}allow_implicit_invocation:\s*(true|false)\s*$", text
    )
    if len(policy_match) != 1:
        fail(
            f"{metadata_path}: policy.allow_implicit_invocation must be "
            "present exactly once"
        )



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
    unexpected_keys = sorted(set(frontmatter) - {"name", "description"})
    if unexpected_keys:
        fail("unsupported frontmatter keys: " + ", ".join(unexpected_keys))
    name = frontmatter.get("name", "")
    if name not in SKILL_SPECS:
        fail("unknown skill name")
    if not frontmatter.get("description", "").strip():
        fail("frontmatter description must not be empty")

    spec = SKILL_SPECS[name]
    title = spec["title"]
    if len(re.findall(rf"(?m)^# {re.escape(title)}\s*$", text)) != 1:
        fail(f"expected exactly one '# {title}' title")

    section_numbers = [
        int(number) for number in re.findall(r"(?m)^##\s+(\d+)\.\s+", text)
    ]
    if section_numbers != spec["sections"]:
        fail(f"numbered sections do not match contract: {section_numbers}")

    line_count = len(text.splitlines())
    if line_count > spec["max_lines"]:
        fail(f"{name} exceeds {spec['max_lines']} lines: {line_count}")
    if len(re.findall(r"(?m)^```", text)) % 2:
        fail("unbalanced fenced code blocks")

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
        fail("Invocation Contract is missing options: " + ", ".join(missing_options))

    required = [*COMMON_REQUIRED, *spec["required_phrases"]]
    missing_phrases = [phrase for phrase in required if phrase not in text]
    if missing_phrases:
        fail("missing required safeguards: " + "; ".join(missing_phrases))

    forbidden = [
        pattern for pattern in spec["forbidden_patterns"] if re.search(pattern, text)
    ]
    if forbidden:
        fail("forbidden standalone dependencies found: " + "; ".join(forbidden))

    if any(
        re.search(pattern, text)
        for pattern in [r"\[Describe ", r"\[Specific action", r"(?m)^\s*(?:TODO|TBD)(?:[:\s]|$)"]
    ):
        fail("unresolved template placeholder found")

    print(f"ok: {path} ({line_count} lines, {len(raw)} bytes)")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("path", nargs="?", default="SKILL.md")
    args = parser.parse_args()
    validate(Path(args.path))


if __name__ == "__main__":
    main()
