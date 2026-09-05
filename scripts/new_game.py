#!/usr/bin/env python3
"""Rename the template into your new game.

Run this once, right after creating a repository from the template:

    python3 scripts/new_game.py --name "Space Rocks" --repo yourname/space-rocks

It rewrites every occurrence of the example game's names (Coin Dash / coin_dash /
coin-dash / CoinDash / coindash), the template repository's name and URLs
(findingsimple/game-scaffolding, findingsimple.github.io/game-scaffolding, and the bare
game-scaffolding), the macOS bundle identifier, resets the version and changelog, and
deletes TEMPLATE.md.

The example game's *code* under game/ is left in place as a working reference —
delete it when you are ready (see TEMPLATE.md for how).

Standard library only. Use --dry-run to preview. Refuses to run on a dirty git
worktree unless --force is given, so a bad rename is always one `git checkout .` away.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Identifiers used by the shipped example. Replacement order matters: most specific first.
EXAMPLE = {
    "display": "Coin Dash",
    "pascal": "CoinDash",
    "snake": "coin_dash",
    "kebab": "coin-dash",
    "flat": "coindash",
    "bundle_id": "com.findingsimple.coindash",
    "repo": "findingsimple/game-scaffolding",
    "pages": "findingsimple.github.io/game-scaffolding",
    "repo_name": "game-scaffolding",
}

# Never rewritten: third-party code, git internals, generated output, this script's tests.
SKIP_PREFIXES = (
    "addons/",
    ".git/",
    ".godot/",
    "build/",
    "reports/",
    "scripts/new_game.py",
    "scripts/test_new_game.py",
)
SKIP_SUFFIXES = (
    ".png",
    ".jpg",
    ".jpeg",
    ".webp",
    ".ogg",
    ".wav",
    ".mp3",
    ".ttf",
    ".otf",
    ".pyc",
)
INITIAL_VERSION = "0.0.0"  # release-please bumps the first feat/fix to 0.1.0

NAME_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 _-]*$")
REPO_RE = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
BUNDLE_RE = re.compile(r"^[A-Za-z][A-Za-z0-9-]*(\.[A-Za-z][A-Za-z0-9-]*)+$")


class InvalidInput(ValueError):
    """Raised for command-line values that would corrupt project files."""


def validate(
    name: str, repo: str, description: str | None, bundle_id: str | None
) -> None:
    for label, value in (
        ("--name", name),
        ("--repo", repo),
        ("--description", description),
        ("--bundle-id", bundle_id),
    ):
        if value is not None and any(ord(c) < 32 or ord(c) == 127 for c in value):
            raise InvalidInput(
                f"{label} must not contain control characters or newlines"
            )
    if not NAME_RE.match(name):
        raise InvalidInput(
            "--name may only contain letters, digits, spaces, '-' and '_', and must start with a letter or digit"
        )
    if not REPO_RE.match(repo):
        raise InvalidInput("--repo must look like owner/name")
    if description is not None and '"' in description:
        raise InvalidInput(
            "--description must not contain double quotes (it is written into project.godot)"
        )
    if bundle_id is not None and not BUNDLE_RE.match(bundle_id):
        raise InvalidInput("--bundle-id must be reverse-DNS, e.g. com.you.yourgame")


def derive_names(display: str) -> dict[str, str]:
    words = re.findall(r"[A-Za-z0-9]+", display)
    if not words:
        raise InvalidInput(f"--name {display!r} has no letters or digits")
    lower = [w.lower() for w in words]
    return {
        "display": display,
        "pascal": "".join(w[:1].upper() + w[1:] for w in words),
        "snake": "_".join(lower),
        "kebab": "-".join(lower),
        "flat": "".join(lower),
    }


def replacements(
    new: dict[str, str], repo: str, bundle_id: str
) -> list[tuple[str, str]]:
    owner, repo_name = repo.split("/", 1)
    return [
        (EXAMPLE["pages"], f"{owner}.github.io/{repo_name}"),
        (EXAMPLE["repo"], repo),
        (EXAMPLE["repo_name"], repo_name),
        (EXAMPLE["bundle_id"], bundle_id),
        (EXAMPLE["display"], new["display"]),
        (EXAMPLE["pascal"], new["pascal"]),
        (EXAMPLE["snake"], new["snake"]),
        (EXAMPLE["kebab"], new["kebab"]),
        (EXAMPLE["flat"], new["flat"]),
    ]


def apply(text: str, pairs: list[tuple[str, str]]) -> tuple[str, int]:
    """Apply replacements in order; returns (new_text, number_of_substitutions)."""
    count = 0
    for old, replacement in pairs:
        hits = text.count(old)
        if hits:
            count += hits
            text = text.replace(old, replacement)
    return text, count


def tracked_files() -> list[Path]:
    out = subprocess.run(
        ["git", "ls-files", "-z"], cwd=ROOT, check=True, capture_output=True
    ).stdout
    files = [ROOT / p for p in out.decode().split("\0") if p]
    return [
        f
        for f in files
        if not f.relative_to(ROOT).as_posix().startswith(SKIP_PREFIXES)
        and not f.name.lower().endswith(SKIP_SUFFIXES)
        and f.is_file()
    ]


def worktree_is_dirty() -> bool:
    out = subprocess.run(
        ["git", "status", "--porcelain"], cwd=ROOT, check=True, capture_output=True
    ).stdout
    return bool(out.strip())


def rewrite(path: Path, pairs: list[tuple[str, str]], dry_run: bool) -> int:
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return 0
    new_text, count = apply(text, pairs)
    if count and not dry_run:
        path.write_text(new_text, encoding="utf-8")
    return count


def set_description(description: str, dry_run: bool) -> None:
    project = ROOT / "project.godot"
    text = project.read_text(encoding="utf-8")
    line = f'config/description="{description}"'
    new_text = re.sub(r"(?m)^config/description=.*$", lambda _m: line, text)
    if new_text != text:
        print("  set      project.godot config/description")
        if not dry_run:
            project.write_text(new_text, encoding="utf-8")


def reset_version_files(dry_run: bool) -> None:
    updates = {
        "version.txt": f"{INITIAL_VERSION}\n",
        ".release-please-manifest.json": f'{{\n  ".": "{INITIAL_VERSION}"\n}}\n',
        "CHANGELOG.md": "# Changelog\n\nAll notable changes to this project are documented here.\n"
        "Generated by release-please from conventional commits; do not edit by hand.\n",
    }
    for name, content in updates.items():
        path = ROOT / name
        if path.exists():
            print(f"  reset    {name}")
            if not dry_run:
                path.write_text(content, encoding="utf-8")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "--name", required=True, help='Display name, e.g. "Space Rocks"'
    )
    parser.add_argument(
        "--repo",
        required=True,
        help="GitHub owner/name of the NEW repository (README links, badges, Pages URL)",
    )
    parser.add_argument(
        "--description", default=None, help="One-line description for project.godot"
    )
    parser.add_argument(
        "--bundle-id",
        default=None,
        help="macOS bundle id (default: com.<owner>.<flatname>)",
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="Print what would change; write nothing"
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Run even if the git worktree has uncommitted changes",
    )
    args = parser.parse_args(argv)

    try:
        validate(args.name, args.repo, args.description, args.bundle_id)
        new = derive_names(args.name)
    except InvalidInput as err:
        print(f"error: {err}", file=sys.stderr)
        return 2

    if not args.dry_run and not args.force and worktree_is_dirty():
        print(
            "error: git worktree has uncommitted changes; commit or stash them first, or pass --force",
            file=sys.stderr,
        )
        return 2

    owner = args.repo.split("/", 1)[0]
    bundle_id = (
        args.bundle_id or f"com.{re.sub(r'[^a-z0-9]', '', owner.lower())}.{new['flat']}"
    )
    pairs = replacements(new, args.repo, bundle_id)

    mode = "DRY RUN — " if args.dry_run else ""
    print(f"{mode}Renaming {EXAMPLE['display']!r} -> {args.name!r}")
    for old, replacement in pairs:
        print(f"  {old:44} -> {replacement}")
    print()

    total = 0
    for path in tracked_files():
        count = rewrite(path, pairs, args.dry_run)
        if count:
            total += count
            print(f"  {count:3d}x  {path.relative_to(ROOT).as_posix()}")

    if args.description is not None:
        set_description(args.description, args.dry_run)
    reset_version_files(args.dry_run)

    template_md = ROOT / "TEMPLATE.md"
    if template_md.exists():
        print("  delete   TEMPLATE.md")
        if not args.dry_run:
            template_md.unlink()

    print(f"\n{total} replacement(s) in tracked files.")
    if args.dry_run:
        print("Nothing was written (dry run).")
    else:
        print(
            "Next: open the project in Godot once, run `make ci`, then commit the rename."
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
