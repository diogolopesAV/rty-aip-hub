#!/usr/bin/env python3
"""
Normalize GitHub shorthand URLs in apm-pack-generated marketplace files.

apm pack intentionally emits "owner/repo" shorthand for GitHub.com packages.
This is mandated by the APM spec (section 7 of manifest-schema): "github.com
is the default host and MUST be stripped." There is no apm.yml configuration
to override this — every form of source (bare shorthand, https://, github.com
prefix, or sourceBase) produces the same shorthand output.

Claude Code (and likely Codex) fail to install plugins with shorthand URLs
because they expand "owner/repo" to an SSH URL (git@github.com:owner/repo.git)
instead of HTTPS. This affects two source types that apm pack emits:

  git-subdir (subdir packages):
    apm pack emits: {"source":"git-subdir","url":"owner/repo","path":"..."}
    Claude Code: tries git@github.com:owner/repo.git → SSH fail
    Fix: change url → "https://github.com/owner/repo" (same source type)

  github (non-subdir external packages):
    apm pack emits: {"source":"github","repo":"owner/repo"}
    Claude Code: accepts only "owner/repo" in repo field (rejects https:// there),
                 tries git@github.com:owner/repo.git → SSH fail
    Fix: convert to {"source":"url","url":"https://github.com/owner/repo"}
         The "url" source type clones via HTTPS directly and is what apm pack
         emits for non-default hosts — confirmed working with Claude Code.

This script applies both conversions after apm pack runs.
Remove it once Claude Code (and Codex) handle the owner/repo shorthand correctly.

Targets:
    .claude-plugin/marketplace.json   (Claude Code format, written by apm pack)
    .agents/plugins/marketplace.json  (Codex format, written by apm pack)

Usage:
    python scripts/normalize-marketplace-urls.py           # normalize in place
    python scripts/normalize-marketplace-urls.py --check   # validate (CI mode)

Run from the repository root.
"""
import argparse
import difflib
import json
import re
import sys
from pathlib import Path

_TARGETS = [
    ".claude-plugin/marketplace.json",
    ".agents/plugins/marketplace.json",
]

# Matches bare "owner/repo" — two path segments, no protocol, no host, no extra slashes.
_SHORTHAND_RE = re.compile(r"^[^/:\s]+/[^/:\s]+$")


def _normalize_doc(doc: dict) -> tuple[dict, bool]:
    """Expand GitHub shorthand URLs/repos in a marketplace document.

    Two conversions:
      git-subdir + url:"owner/repo"  →  git-subdir + url:"https://github.com/owner/repo"
      github     + repo:"owner/repo" →  url        + url:"https://github.com/owner/repo"

    Returns the (potentially mutated) document and a changed flag.
    """
    changed = False
    for plugin in doc.get("plugins", []):
        src = plugin.get("source")
        if not isinstance(src, dict):
            continue

        source_type = src.get("source")

        if source_type == "git-subdir":
            url = src.get("url", "")
            if _SHORTHAND_RE.fullmatch(url):
                src["url"] = f"https://github.com/{url}"
                changed = True

        elif source_type == "github":
            repo = src.get("repo", "")
            if _SHORTHAND_RE.fullmatch(repo):
                # Convert: github + shorthand repo → url + HTTPS
                # The "url" source type is what apm pack uses for non-default hosts;
                # Claude Code accepts it and clones via HTTPS. The "github" source type
                # only accepts "owner/repo" shorthand in its repo field and tries SSH.
                del src["repo"]
                src["source"] = "url"
                src["url"] = f"https://github.com/{repo}"
                # Move url to be right after source for readability
                ordered = {"source": src.pop("source"), "url": src.pop("url")}
                ordered.update(src)
                plugin["source"] = ordered
                src = ordered
                changed = True

    return doc, changed


def _normalize_file(path: Path) -> tuple[str, bool]:
    """Read, normalize, and return (new_content, changed) for a marketplace file."""
    doc = json.loads(path.read_text(encoding="utf-8"))
    doc, changed = _normalize_doc(doc)
    return json.dumps(doc, indent=2, ensure_ascii=False) + "\n", changed


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help=(
            "Validate that the committed files are already normalized. "
            "Exits non-zero if any shorthand URL/repo is found or a file is "
            "missing. Useful as a CI gate on PRs."
        ),
    )
    args = parser.parse_args()

    any_failure = False

    for target_str in _TARGETS:
        path = Path(target_str)

        if not path.exists():
            print(f"skip: {target_str} does not exist", file=sys.stderr)
            continue

        new_content, changed = _normalize_file(path)

        if args.check:
            existing = path.read_text(encoding="utf-8")
            if existing != new_content:
                diff = "".join(difflib.unified_diff(
                    existing.splitlines(keepends=True),
                    new_content.splitlines(keepends=True),
                    fromfile=f"{target_str} (committed)",
                    tofile=f"{target_str} (normalized)",
                    n=3,
                ))
                print(
                    f"check failed: {target_str} contains un-normalized GitHub "
                    f"shorthand URLs.\n"
                    f"Run 'python scripts/normalize-marketplace-urls.py' locally "
                    f"and commit the result.\n",
                    file=sys.stderr,
                )
                print(diff, file=sys.stderr)
                any_failure = True
            else:
                print(f"check passed: {target_str}")
        else:
            if changed:
                path.write_text(new_content, encoding="utf-8")
                print(f"normalized: {target_str}")
            else:
                print(f"ok (no changes): {target_str}")

    if any_failure:
        sys.exit(1)


if __name__ == "__main__":
    main()
