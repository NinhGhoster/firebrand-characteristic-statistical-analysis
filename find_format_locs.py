import os
import csv
from collections import defaultdict

root_dir = "."
format_locations = defaultdict(set)

for root, dirs, files in os.walk(root_dir):
    for file in files:
        if file.endswith(".csv"):
            file_path = os.path.join(root, file)
            try:
                with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                    reader = csv.reader(f)
                    header = next(reader)
                    if 'Volume (mm)' in header:
                        format_locations['Volume (mm)'].add(root)
                    if 'Volume (mm3)' in header:
                        format_locations['Volume (mm3)'].add(root)
            except Exception:
                pass

print("--- Locations of Volume Formats ---")
for fmt, locs in format_locations.items():
    print(f"Format: '{fmt}'")
    for loc in sorted(locs):
        print(f"  - {loc}")
