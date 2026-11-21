"""
Fix artists.dat and tags.dat so that Neo4j LOAD CSV can read them.

Problem:
  - 16 artist names contain a double quote (e.g. Weird Al" Yankovic).
    LOAD CSV treats " as a field delimiter and fails.
  - tags.dat is encoded in Latin-1, not UTF-8.

Fix:
  Each line is split on tabs only (quotes are ordinary characters), then the
  file is written back as standard CSV: UTF-8, every field quoted, inner
  quotes doubled (""). No value is changed.

Usage:
  python src/clean_text_files.py <folder containing the .dat files>
Output:
  artists_clean.tsv and tags_clean.tsv in the same folder.
"""
import csv
import sys
from pathlib import Path

if len(sys.argv) != 2:
    sys.exit("Usage: python src/clean_text_files.py <folder with the .dat files>")

folder = Path(sys.argv[1])

for name in ["artists", "tags"]:
    raw = (folder / f"{name}.dat").read_bytes()

    try:
        text, enc = raw.decode("utf-8"), "utf-8"
    except UnicodeDecodeError:
        text, enc = raw.decode("latin-1"), "latin-1"

    rows = [line.split("\t") for line in text.splitlines() if line.strip()]
    header, data = rows[0], rows[1:]

    out = folder / f"{name}_clean.tsv"
    with open(out, "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f, delimiter="\t", quoting=csv.QUOTE_ALL)
        writer.writerow(header)
        writer.writerows(data)

    bad = sum(1 for r in data if len(r) != len(header))
    quotes = sum(1 for r in data if any('"' in x for x in r))
    print(f"{name}.dat: encoding={enc}, rows={len(data)}, "
          f"rows with a quote={quotes}, malformed rows={bad} -> {out.name}")
