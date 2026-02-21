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
    'Volume (mmÂ³)': 'Volume (mm3)',
    'Surface Area (mmÂ²)': 'Surface Area (mm2)'
}

for root, dirs, files in os.walk(root_dir):
    for file in files:
        if file.endswith(".csv"):
            file_path = os.path.join(root, file)
            try:
                # Read the header only first
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    reader = csv.reader(f)
                    header = next(reader)
                
                needs_update = False
                for col in header:
                    if col in rename_map:
                        needs_update = True
                        break
                
                if needs_update:
                    # Read full data - Note: removed errors='ignore' as it's not supported in all pandas versions
                    # Using engine='python' and encoding='utf-8' with on_bad_lines logic if needed
                    df = pd.read_csv(file_path, encoding='utf-8')
                    
                    # Rename columns
                    df.columns = [rename_map.get(col, col) for col in df.columns]
                    
                    # Save back
                    df.to_csv(file_path, index=False)
                    files_updated += 1
                    if files_updated <= 5 or files_updated % 50 == 0:
                        print(f"Updated: {file_path}")
            except Exception as e:
                # If utf-8 fails, try latin1
                try:
                    df = pd.read_csv(file_path, encoding='latin1')
                    df.columns = [rename_map.get(col, col) for col in df.columns]
                    df.to_csv(file_path, index=False)
                    files_updated += 1
                    print(f"Updated (latin1 fallback): {file_path}")
                except Exception as e2:
                    print(f"Error processing {file_path}: {e2}")

print(f"\nTotal CSV files updated to 'Volume (mm3)' and 'Surface Area (mm2)': {files_updated}")
