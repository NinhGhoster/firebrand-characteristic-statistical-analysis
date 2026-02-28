import openpyxl

# Load the stringybark file
wb = openpyxl.load_workbook('/Users/firecaster/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Documents/Chapter 2/Chapter 2 data/Stringybark/stringybark.xlsx')
ws = wb.active

print("Header Row Color Formatting:")
for col in range(1, 6):
    cell = ws.cell(1, col)
    print(f"\nColumn {col} - {cell.value}:")
    
    # Font color
    if cell.font.color:
        if hasattr(cell.font.color, 'rgb') and cell.font.color.rgb:
            print(f"  Font RGB: {cell.font.color.rgb}")
        if hasattr(cell.font.color, 'theme'):
            print(f"  Font Theme: {cell.font.color.theme}")
        if hasattr(cell.font.color, 'tint'):
            print(f"  Font Tint: {cell.font.color.tint}")
    
    # Fill color
    print(f"  Fill Pattern: {cell.fill.patternType}")
    if cell.fill.patternType and cell.fill.patternType != 'none':
        if cell.fill.fgColor:
            print(f"    FG Color RGB: {cell.fill.fgColor.rgb if hasattr(cell.fill.fgColor, 'rgb') and cell.fill.fgColor.rgb else 'None'}")
            print(f"    FG Color Theme: {cell.fill.fgColor.theme if hasattr(cell.fill.fgColor, 'theme') else 'None'}")
        if cell.fill.bgColor:
            print(f"    BG Color RGB: {cell.fill.bgColor.rgb if hasattr(cell.fill.bgColor, 'rgb') and cell.fill.bgColor.rgb else 'None'}")
