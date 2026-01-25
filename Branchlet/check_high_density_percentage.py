import pandas as pd

file_path = 'branchlet raw data.xlsx'
xls = pd.ExcelFile(file_path)

# Filter for analyzed sheets
analyzed_sheets = [s for s in xls.sheet_names if "(raw)" not in s]

print(f"Percentage of firebrands with Density > 800 kg/m3:\n")
print(f"{'Sheet Name':<25} | {'Total Rows':<10} | {'> 800 Count':<12} | {'Percentage':<10}")
print("-" * 65)

for sheet in analyzed_sheets:
    try:
        df = pd.read_excel(xls, sheet_name=sheet)
        
        # Check for explicit Density column
        density_col = next((c for c in df.columns if "Density" in c), None)
        
        if density_col:
            # Clean data (drop NaNs in density column)
            densities = df[density_col].dropna()
            total_count = len(densities)
            
            if total_count > 0:
                high_density_count = (densities > 800).sum()
                percentage = (high_density_count / total_count) * 100
                
                print(f"{sheet:<25} | {total_count:<10} | {high_density_count:<12} | {percentage:.2f}%")
            else:
                print(f"{sheet:<25} | {'0':<10} | {'0':<12} | {'N/A'}")
        else:
             # Just skip silently for now as we only care about sheets with Density
             pass

    except Exception as e:
        print(f"Error reading sheet {sheet}: {e}")
