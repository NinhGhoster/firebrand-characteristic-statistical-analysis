import pandas as pd
import os

file_path = 'Branchlet/branchlet raw data.xlsx'

if not os.path.exists(file_path):
    print(f"File not found: {file_path}")
    exit(1)

try:
    xls = pd.ExcelFile(file_path)
    
    # helper dictionary to store all sheets
    all_sheets = {}
    
    # Read all sheets first
    for sheet_name in xls.sheet_names:
        df = pd.read_excel(xls, sheet_name=sheet_name)
        
        if 'Calibration' in df.columns and 'Mass (g)' in df.columns:
            mask = df['Calibration'] == 'cali'
            if mask.any():
                print(f"Rounding 'Mass (g)' for 'cali' rows in sheet: {sheet_name}")
                # Round to 3 decimal places
                df.loc[mask, 'Mass (g)'] = df.loc[mask, 'Mass (g)'].round(3)
        
        all_sheets[sheet_name] = df

    # Save all sheets back to the file
    with pd.ExcelWriter(file_path, engine='openpyxl') as writer:
        for sheet_name, df in all_sheets.items():
            df.to_excel(writer, sheet_name=sheet_name, index=False)
            
    print("Successfully updated 'Mass (g)' precision for calibrated rows.")

except Exception as e:
    print(f"An error occurred: {e}")
