import os
import pandas as pd
from pathlib import Path

# Define the base directory
base_dir = "/Users/firecaster/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Documents/Chapter 2/Chapter 2 data/Candle bark"

# Get all folders (exclude files)
folders = [d for d in os.listdir(base_dir) if os.path.isdir(os.path.join(base_dir, d))]
folders.sort()

# Create Excel writer
output_file = os.path.join(base_dir, "Combined_Data.xlsx")
excel_writer = pd.ExcelWriter(output_file, engine='openpyxl')

print(f"Processing {len(folders)} folders...")

# Process each folder
for folder_name in folders:
    folder_path = os.path.join(base_dir, folder_name)
    csv_files = [f for f in os.listdir(folder_path) if f.endswith('.csv')]
    csv_files.sort()
    
    if not csv_files:
        print(f"⚠️  No CSV files in: {folder_name}")
        continue
    
    print(f"\nProcessing: {folder_name} ({len(csv_files)} files)")
    
    # Combine all CSVs in this folder
    dfs = []
    for csv_file in csv_files:
        csv_path = os.path.join(folder_path, csv_file)
        df = None
        # Try multiple encodings
        for encoding in ['utf-8', 'latin-1', 'iso-8859-1', 'cp1252']:
            try:
                df = pd.read_csv(csv_path, encoding=encoding)
                # Add a column to identify which file the data came from
                df['Source.Name'] = csv_file
                dfs.append(df)
                print(f"  ✓ {csv_file}")
                break
            except Exception as e:
                if encoding == 'cp1252':
                    print(f"  ✗ Error reading {csv_file}: {e}")
                continue
    
    if dfs:
        # Combine all dataframes
        combined_df = pd.concat(dfs, ignore_index=True)
        # Move Source.Name column to first position
        cols = combined_df.columns.tolist()
        cols.remove('Source.Name')
        combined_df = combined_df[['Source.Name'] + cols]
        
        # Sanitize sheet name (Excel has 31 char limit and special char restrictions)
        sheet_name = folder_name[:31].replace('/', '_').replace('\\', '_').replace('?', '_').replace('*', '_').replace('[', '_').replace(']', '_').replace(':', '_')
        
        # Write to Excel
        combined_df.to_excel(excel_writer, sheet_name=sheet_name, index=False)
        print(f"  ✓ Written to sheet: {sheet_name} ({len(combined_df)} rows)")

excel_writer.close()
print(f"\n✓ Excel file created: {output_file}")
