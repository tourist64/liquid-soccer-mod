#!/usr/bin/env python3
"""Build the direct remaster pack from the source export and complete base PCK."""

from pathlib import Path
import argparse
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from modloader import read_pck, write_pck


def merge_resource_packs(base_path: Path, source_path: Path, output_path: Path) -> None:
    header, base_entries = read_pck(base_path)
    _, source_entries = read_pck(source_path)
    source_by_path = {entry.path: entry for entry in source_entries}
    merged = []
    seen = set()

    for entry in base_entries:
        merged.append(source_by_path.get(entry.path, entry))
        seen.add(entry.path)
    merged.extend(entry for entry in source_entries if entry.path not in seen)
    write_pck(output_path, header, merged)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", type=Path, required=True)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    merge_resource_packs(args.base, args.source, args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
