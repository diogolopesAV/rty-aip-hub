#!/usr/bin/env python3
"""
Generate Copilot CLI and Cursor marketplace catalog JSON files.

apm pack generates .claude-plugin/marketplace.json and .agents/plugins/marketplace.json
but does not support Copilot CLI or Cursor catalog output. This script fills that gap by
reading the same apm.yml marketplace block and translating it to the target format.

Format sources:
  Copilot: github/awesome-copilot live catalog + docs.github.com CLI plugin reference
  Cursor:  confirmed format from Cursor team (.cursor-plugin/marketplace.json)

Usage:
    python scripts/gen-copilot-marketplace.py                        # Copilot (default)
    python scripts/gen-copilot-marketplace.py --format cursor        # Cursor
    python scripts/gen-copilot-marketplace.py --check                # validate (CI mode)
    python scripts/gen-copilot-marketplace.py --format cursor --check

Run from the repository root.
"""
import argparse
import json
import os
import sys
import tempfile

try:
    import yaml
except ImportError:
    print("error: PyYAML not installed. Run: pip install pyyaml", file=sys.stderr)
    sys.exit(1)

_FORMAT_OUTPUT_PATHS = {
    "copilot": ".github/plugin/marketplace.json",
    "cursor": ".cursor-plugin/marketplace.json",
}
APM_YML_PATH = "apm.yml"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def load_apm_yml() -> dict:
    with open(APM_YML_PATH, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def strip_dot_slash(path: str) -> str:
    """Remove leading './' so local paths match what awesome-copilot uses."""
    return path[2:] if path.startswith("./") else path


def is_local_source(source: str) -> bool:
    """
    A source is local when it is a relative or absolute filesystem path.
    apm.yml convention: local sources start with './'
    External sources are 'owner/repo' GitHub shorthands (no leading dot-slash).
    """
    return source.startswith("./") or source.startswith("/")


def build_plugin_entry(pkg: dict, fmt: str = "copilot") -> dict:
    """
    Translate one apm.yml marketplace package into a catalog entry.

    Confirmed entry fields:
        name         – required
        source       – required; bare path string OR {"source":"github","repo":...,"ref":...}
        description  – optional
        version      – optional; semver
        author       – optional; {"name":..., "url":...}
        repository   – optional; URL string
        license      – optional; SPDX string
        category     – optional; category string (supported by both formats)
        keywords     – optional; string[] (apm.yml uses 'tags' — we remap)
    """
    source_val = str(pkg["source"])
    entry: dict = {"name": pkg["name"]}

    # Source
    if is_local_source(source_val):
        entry["source"] = strip_dot_slash(source_val)
    else:
        # External GitHub repo in 'owner/repo' format
        src_obj: dict = {
            "source": "github",
            "repo": source_val,
        }
        ref = pkg.get("ref")
        if ref:
            ref_str = str(ref)
            # Copilot CLI convention (confirmed from github/awesome-copilot):
            #   - named refs (tags, branches) → "ref" field
            #   - commit SHAs               → "sha" field (dedicated, not inside "ref")
            # Cursor convention (confirmed by Cursor team): only "ref" field documented.
            #   We keep SHA in "ref" for Cursor until Cursor explicitly documents "sha".
            is_sha = len(ref_str) == 40 and all(c in "0123456789abcdef" for c in ref_str)
            if is_sha and fmt == "copilot":
                src_obj["sha"] = ref_str
            else:
                src_obj["ref"] = ref_str
        entry["source"] = src_obj

    # Optional metadata — remap apm.yml field names to Copilot field names
    if "description" in pkg:
        entry["description"] = pkg["description"]
    if "version" in pkg:
        entry["version"] = pkg["version"]
    if "license" in pkg:
        entry["license"] = pkg["license"]
    if "category" in pkg:
        entry["category"] = pkg["category"]

    # 'tags' in apm.yml → 'keywords' in Copilot (confirmed from awesome-copilot entries)
    tags = pkg.get("tags")
    if tags:
        entry["keywords"] = list(tags)

    return entry


def build_catalog(config: dict, fmt: str = "copilot") -> dict:
    """Build the full marketplace catalog dict (format-agnostic)."""
    mp = config.get("marketplace", {})
    if not mp:
        raise ValueError("no 'marketplace' block found in apm.yml")

    packages = mp.get("packages", [])
    owner_block = mp.get("owner", {})

    # Top-level catalog owner — Copilot uses {name, email}; apm.yml has {name, url}.
    owner: dict = {"name": owner_block.get("name", "")}
    if "email" in owner_block:
        owner["email"] = owner_block["email"]
    # 'url' is not in the Copilot owner schema, so we omit it.

    # Optional top-level metadata (description, version) — from the hub root config
    metadata: dict = {}
    if config.get("description"):
        metadata["description"] = config["description"]
    if config.get("version"):
        metadata["version"] = config["version"]

    catalog: dict = {
        "name": mp["name"],
    }
    if metadata:
        catalog["metadata"] = metadata
    catalog["owner"] = owner
    catalog["plugins"] = [build_plugin_entry(p, fmt) for p in packages]

    return catalog


def validate_catalog(catalog: dict) -> list[str]:
    """
    Return a list of validation error strings (empty = valid).

    Checks:
    - Top-level name is present and non-empty
    - plugins[] is a non-empty list
    - Every entry has a non-empty name and a source
    - Local source paths do not start with './plugins' that don't exist on disk
      (best-effort; skipped if run from a non-root working directory)
    - External entries have a non-empty 'repo' field
    """
    errors: list[str] = []

    if not catalog.get("name"):
        errors.append("catalog 'name' is missing or empty")

    plugins = catalog.get("plugins", [])
    if not plugins:
        errors.append("catalog 'plugins' array is empty")

    for i, entry in enumerate(plugins):
        prefix = f"plugins[{i}] ({entry.get('name', '<unnamed>')})"
        if not entry.get("name"):
            errors.append(f"{prefix}: 'name' is missing or empty")

        source = entry.get("source")
        if source is None:
            errors.append(f"{prefix}: 'source' is missing")
        elif isinstance(source, dict):
            if source.get("source") != "github":
                errors.append(f"{prefix}: external source type must be 'github', got {source.get('source')!r}")
            if not source.get("repo"):
                errors.append(f"{prefix}: external source missing 'repo'")
            if not source.get("ref") and not source.get("sha"):
                errors.append(f"{prefix}: external source has no 'ref' or 'sha' — plugin will resolve to HEAD, which is mutable")
        elif isinstance(source, str):
            if os.path.isdir(".git"):  # Only validate paths when at repo root
                full_path = os.path.join(os.getcwd(), source)
                if not os.path.isdir(full_path):
                    errors.append(f"{prefix}: local source path '{source}' does not exist on disk")
        else:
            errors.append(f"{prefix}: 'source' must be a string or object, got {type(source).__name__}")

    return errors


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument(
        "--format",
        choices=list(_FORMAT_OUTPUT_PATHS.keys()),
        default="copilot",
        help="Target marketplace format (default: copilot).",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help=(
            "Validate the catalog that would be generated without writing the output file. "
            "Exits non-zero if validation fails or if the output file is out of date "
            "(useful as a CI gate on PRs)."
        ),
    )
    args = parser.parse_args()

    output_path = _FORMAT_OUTPUT_PATHS[args.format]

    if not os.path.isfile(APM_YML_PATH):
        print(f"error: {APM_YML_PATH} not found — run from the repository root", file=sys.stderr)
        sys.exit(1)

    config = load_apm_yml()
    catalog = build_catalog(config, args.format)

    # Validate structure
    errors = validate_catalog(catalog)
    if errors:
        print("Validation errors:", file=sys.stderr)
        for err in errors:
            print(f"  - {err}", file=sys.stderr)
        sys.exit(1)

    new_json = json.dumps(catalog, indent=2, ensure_ascii=False) + "\n"

    if args.check:
        # CI mode: compare against what's currently committed
        if not os.path.isfile(output_path):
            print(
                f"check failed: {output_path} does not exist — run "
                f"'python {__file__} --format {args.format} && git add {output_path}' and commit the file",
                file=sys.stderr,
            )
            sys.exit(1)

        with open(output_path, "r", encoding="utf-8") as f:
            existing_json = f.read()

        if new_json != existing_json:
            import difflib
            diff = list(difflib.unified_diff(
                existing_json.splitlines(keepends=True),
                new_json.splitlines(keepends=True),
                fromfile=f"{output_path} (committed)",
                tofile=f"{output_path} (generated from apm.yml)",
                n=3,
            ))
            print(
                f"check failed: {output_path} is out of date with apm.yml.\n"
                f"Run 'python scripts/gen-copilot-marketplace.py --format {args.format}' locally and commit the result.\n",
                file=sys.stderr,
            )
            print("".join(diff), file=sys.stderr)
            sys.exit(1)

        plugin_count = len(catalog["plugins"])
        print(f"check passed: {output_path} is up to date ({plugin_count} plugin(s))")
    else:
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(new_json)
        plugin_count = len(catalog["plugins"])
        print(f"generated {output_path} ({plugin_count} plugin(s))")


if __name__ == "__main__":
    main()
