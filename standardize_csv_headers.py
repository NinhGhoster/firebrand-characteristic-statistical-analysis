import os
import csv
import pandas as pd

root_dir = "."
files_updated = 0

# Target renaming mapping
rename_map = {
    'Volume (mm)': 'Volume (mm3)',
    'Surface Area (mm)': 'Surface Area (mm2)',
    'Volume (mm^3)': 'Volume (mm3)',
    'Surface Area (mm^2)': 'Surface Area (mm2)',
    'Volume (mmÂ³)': 'Volume (mm3)', # Common encoding issue for ³
    'Surface Area (mmÂ²)': 'Surface Area (mm2)' # Common encoding issue for ²
}

for root, dirs, files in os.walk(root_dir):
    for file in files:
        if file.endswith(".csv"):
            file_path = os.path.join(root, file)
            try:
                # Read the header only first to check if rename is needed
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    reader = csv.reader(f)
                    header = next(reader)
                
                needs_update = False
                new_header = []
                for col in header:
                    if col in rename_map:
                        new_header.append(rename_map[col])
                        needs_update = True
                    else:
                        new_header.append(col)
                
                if needs_update:
                    # Read full data and overwrite with new header
                    df = pd.read_csv(file_path, encoding='utf-8', errors='ignore')
                    # Standardize column names
                    df.columns = [rename_map.get(col, col) for col in df.columns]
                    df.to_csv(file_path, index=False)
                    files_updated += 1
                    if files_updated <= 5 or files_updated % 50 == 0:
                        print(f"Updated: {file_path}")
            except Exception as e:
                print(f"Error processing {file_path}: {e}")

print(f"\nTotal CSV files updated to 'Volume (mm3)' and 'Surface Area (mm2)': {files_updated}")
