import os
import csv
from collections import Counter

root_dir = "."
column_counts = Counter()

for root, dirs, files in os.walk(root_dir):
    for file in files:
        if file.endswith(".csv"):
            file_path = os.path.join(root, file)
            try:
                with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                    reader = csv.reader(f)
                    header = next(reader)
                    for col in header:
                        if "mm" in col:
                            column_counts[col] += 1
            except Exception:
                pass

print("--- All 'mm' Column Variations Found ---")
for col, count in sorted(column_counts.items(), key=lambda x: x[1], reverse=True):
    print(f"'{col}': {count}")
