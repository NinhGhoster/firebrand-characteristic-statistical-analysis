import os
import csv
from collections import Counter

root_dir = "."
column_counts = Counter()
files_per_column = {}

for root, dirs, files in os.walk(root_dir):
    for file in files:
        if file.endswith(".csv"):
            file_path = os.path.join(root, file)
            try:
                with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                    reader = csv.reader(f)
                    header = next(reader)
                    # Filter for columns that look like volume
                    vol_cols = [col for col in header if "Volume" in col]
                    for col in vol_cols:
                        column_counts[col] += 1
                        if col not in files_per_column:
                            files_per_column[col] = []
                        if len(files_per_column[col]) < 5: # Keep just a few examples
                            files_per_column[col].append(file_path)
            except Exception as e:
                print(f"Error reading {file_path}: {e}")

print("--- Volume Column Variations Found ---")
for col, count in column_counts.items():
    print(f"Column: '{col}' | Count: {count}")
    print(f"  Examples: {files_per_column[col]}")
