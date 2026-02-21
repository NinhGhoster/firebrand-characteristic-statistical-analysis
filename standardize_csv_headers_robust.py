import os
import csv
import pandas as pd
import re

root_dir = "."
files_updated = 0

def standardize_header(header):
    new_header = []
    updated = False
    for col in header:
        new_col = col
        # Standardize Volume
        if re.search(r'Volume.*mm', col, re.IGNORECASE):
            if col != 'Volume (mm3)':
                new_col = 'Volume (mm3)'
                updated = True
        # Standardize Surface Area
        elif re.search(r'Surface Area.*mm', col, re.IGNORECASE):
            if col != 'Surface Area (mm2)':
                new_col = 'Surface Area (mm2)'
                updated = True
        new_header.append(new_col)
    return new_header, updated

for root, dirs, files in os.walk(root_dir):
    for file in files:
        if file.endswith(".csv"):
            file_path = os.path.join(root, file)
            try:
                # Try UTF-8 first
                try:
                    df = pd.read_csv(file_path, encoding='utf-8')
                    encoding_used = 'utf-8'
                except:
                    df = pd.read_csv(file_path, encoding='latin1')
                    encoding_used = 'latin1'
                
                new_cols, updated = standardize_header(df.columns)
                
                if updated:
                    df.columns = new_cols
                    df.to_csv(file_path, index=False)
                    files_updated += 1
                    if files_updated <= 5 or files_updated % 50 == 0:
                        print(f"Updated ({encoding_used}): {file_path}")
            except Exception as e:
                print(f"Error processing {file_path}: {e}")

print(f"\nTotal CSV files standardized to 'Volume (mm3)' and 'Surface Area (mm2)': {files_updated}")
