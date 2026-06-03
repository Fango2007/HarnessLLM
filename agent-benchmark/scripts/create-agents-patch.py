#!/usr/bin/env python3
"""Register the next prepared Vibe AGENTS patch."""

from __future__ import annotations

import argparse
import re
import shutil
from pathlib import Path


def next_patch_name(patches_dir: Path) -> str:
    pattern = re.compile(r"^agent-candidate-v(\d{3})\.md$")
    versions = []
    for path in patches_dir.iterdir():
        match = pattern.match(path.name)
        if match:
            versions.append(int(match.group(1)))
    return f"agent-candidate-v{max(versions, default=0) + 1:03d}.md"


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Copy a prepared AGENTS patch into prompts/variants/agents-patches/ "
            "using the next agent-candidate-vNNN.md filename."
        )
    )
    parser.add_argument("source", help="Path to the prepared AGENTS patch")
    parser.add_argument(
        "--name",
        help="Optional explicit filename, for example agent-candidate-v002.md",
    )
    args = parser.parse_args()

    benchmark_dir = Path(__file__).resolve().parents[1]
    patches_dir = benchmark_dir / "prompts" / "variants" / "agents-patches"
    source = Path(args.source).expanduser().resolve()

    if not source.is_file():
        raise SystemExit(f"Source prompt does not exist: {source}")

    name = args.name or next_patch_name(patches_dir)
    if "/" in name or not re.match(r"^agent-candidate-v\d{3}\.md$", name):
        raise SystemExit(
            "Patch name must match agent-candidate-vNNN.md and be a filename"
        )

    destination = patches_dir / name
    if destination.exists():
        raise SystemExit(f"Patch already exists: {destination}")

    shutil.copyfile(source, destination)
    print(destination)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
