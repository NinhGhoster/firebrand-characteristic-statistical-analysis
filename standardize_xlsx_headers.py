import pandas as pd
import os
import re

xlsx_files = [
    "./Bulk density/bulk density & MC data.xlsx",
    "./Stringybark/stringybark.xlsx",
    "./Candle bark/Combined_Data.xlsx",
    "./Branchlet/branchlet raw data.xlsx",
    "./Branchlet/branchlet raw data_pre_cali.xlsx"
]

def standardize_header(header):
    new_header = []
    updated = False
    for col in header:
        new_col = col
        if re.search(r'Volume.*mm', str(col), re.IGNORECASE):
            if col != 'Volume (mm3)':
                new_col = 'Volume (mm3)'
                updated = True
        elif re.search(r'Surface Area.*mm', str(col), re.IGNORECASE):
            if col != 'Surface Area (mm2)':
                new_col = 'Surface Area (mm2)'
                updated = True
        new_header.append(new_col)
    return new_header, updated

for file_path in xlsx_files:
    if not os.path.exists(file_path):
        continue
    try:
        xls = pd.ExcelFile(file_path)
        writer = pd.ExcelWriter(file_path + "_temp.xlsx", engine='openpyxl')
        changed = False
        
        for sheet_name in xls.sheet_names:
            df = pd.read_excel(xls, sheet_name=sheet_name)
            new_cols, updated = standardize_header(df.columns)
            if updated:
                df.columns = new_cols
                changed = True
            df.to_excel(writer, sheet_name=sheet_name, index=False)
        
        writer.close()
        
        if changed:
            os.replace(file_path + "_temp.xlsx", file_path)
            print(f"Updated Excel: {file_path}")
        else:
            os.remove(file_path + "_temp.xlsx")
            print(f"Excel already standard: {file_path}")
            
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
