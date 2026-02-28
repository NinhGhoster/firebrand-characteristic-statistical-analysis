import openpyxl
import pandas as pd
from openpyxl.utils import get_column_letter

# Load the Combined_Data file
excel_file = '/Users/firecaster/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Documents/Chapter 2/Chapter 2 data/Candle bark/Combined_Data.xlsx'
xls = pd.ExcelFile(excel_file)

print("=" * 80)
print("DATA VALIDATION REPORT - Combined_Data.xlsx")
print("=" * 80)

total_issues = 0

for sheet_name in xls.sheet_names:
    df = pd.read_excel(excel_file, sheet_name=sheet_name)
    print(f"\n{'─' * 80}")
    print(f"Sheet: {sheet_name}")
    print(f"{'─' * 80}")
    print(f"Rows: {len(df)}, Columns: {len(df.columns)}")
    
    sheet_issues = 0
    
    # Check for missing values
    missing = df.isnull().sum()
    if missing.sum() > 0:
        print(f"\n⚠️  Missing Values:")
        for col, count in missing[missing > 0].items():
            print(f"   {col}: {count} missing")
            sheet_issues += 1
    
    # Check for duplicates (based on Source.Name and other key columns)
    duplicates = df.duplicated(subset=['Source.Name'] if 'Source.Name' in df.columns else None, keep=False).sum()
    if duplicates > 0:
        print(f"\n⚠️  Duplicate rows (by Source.Name): {duplicates}")
        sheet_issues += 1
    
    # Check numeric columns for outliers (values that seem off)
    numeric_cols = df.select_dtypes(include=['number']).columns
    for col in numeric_cols:
        # Check for negative values (if shouldn't be)
        if 'Volume' in col or 'Surface' in col or 'Length' in col or 'Diameter' in col:
            if (df[col] < 0).any():
                neg_count = (df[col] < 0).sum()
                print(f"\n⚠️  {col}: {neg_count} negative values (may be invalid)")
                sheet_issues += 1
    
    # Data type consistency
    print(f"\nColumn Data Types:")
    for col in df.columns:
        print(f"   {col}: {df[col].dtype}")
    
    if sheet_issues == 0:
        print(f"\n✓ No issues detected in this sheet")
    
    total_issues += sheet_issues

print(f"\n{'=' * 80}")
print(f"SUMMARY: {'✓ All sheets validated successfully!' if total_issues == 0 else f'⚠️  {total_issues} potential issues found'}")
print(f"{'=' * 80}\n")
