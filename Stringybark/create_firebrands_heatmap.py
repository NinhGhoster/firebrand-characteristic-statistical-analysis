import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import re
import numpy as np

# File path
file_path = '/Users/firecaster/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Documents/Chapter 2/Chapter 2 data/Stringybark/stringybark.xlsx'

# Load the workbook
xls = pd.ExcelFile(file_path)
sheet_names = xls.sheet_names

# Dictionary to store aggregated data
all_data = []

# Process each sheet (tree)
for sheet_name in sheet_names:
    df = pd.read_excel(file_path, sheet_name=sheet_name)
    
    # Extract section number from File ID (e.g., "S5a_mesh_4.ply" -> "S5")
    df['Section'] = df.iloc[:, 1].astype(str).str.extract(r'(S\d+)')
    
    # Rename columns for easier access
    df.rename(columns={df.columns[1]: 'File_ID', df.columns[2]: 'Volume'}, inplace=True)
    
    # Count number of records (firebrands) per section
    section_count = df.groupby('Section').size().reset_index(name='Count')
    section_count['Tree'] = sheet_name
    
    # Extract section number as integer for sorting
    section_count['Section_num'] = section_count['Section'].str.extract(r'(\d+)').astype(int)
    
    all_data.append(section_count)

# Combine all data
combined_df = pd.concat(all_data, ignore_index=True)

# ==================== HEATMAP: NUMBER OF FIREBRANDS ====================
# Prepare data for heatmap - pivot to get trees as columns and sections as rows
heatmap_data = combined_df.pivot_table(index='Section_num', columns='Tree', values='Count', fill_value=0)

# Reorder columns: T8, T5, T9, T16, T17
tree_order = ['E  radiata 0% char T8', 'E  obliqua 0% char T5', 'E  obliqua 10-50% char T9', 
              'E  obliqua 50-90% char T16', 'E  obliqua 90% char T17']
heatmap_data = heatmap_data[tree_order]

# Find the maximum section number for each tree
tree_max_sections = combined_df.groupby('Tree')['Section_num'].max()

# Create a range from 1 to max of all sections
max_section = heatmap_data.index.max()
all_sections = pd.DataFrame({'Section_num': range(1, int(max_section) + 1)})
heatmap_data = all_sections.set_index('Section_num').join(heatmap_data)

# Fill within-range values with 0
heatmap_data = heatmap_data.fillna(0)

# Create a mask to hide sections beyond each tree's max
mask = pd.DataFrame(False, index=heatmap_data.index, columns=heatmap_data.columns)
for tree in heatmap_data.columns:
    max_sec = tree_max_sections.get(tree, 0)
    mask.loc[mask.index > max_sec, tree] = True

# Reverse the index so S1 is at the bottom and highest section is at the top
heatmap_data = heatmap_data.iloc[::-1]
mask = mask.iloc[::-1]

fig, ax = plt.subplots(figsize=(10, 14))

# Create heatmap with number of firebrands, using mask to hide sections beyond each tree's max
sns.heatmap(heatmap_data, cmap='YlOrRd', cbar_kws={'label': 'Number of Firebrands'}, 
            linewidths=0.5, linecolor='gray', ax=ax, annot=True, fmt='.0f', cbar=True, mask=mask)

ax.set_xlabel('Tree species & char level', fontsize=12, fontweight='bold')
ax.set_ylabel('Trunk section height (bottom S1 → top)', fontsize=12, fontweight='bold')

# Adjust y-axis labels to show section numbers from top to bottom
max_section_num = len(heatmap_data)
y_labels = [f'S{max_section_num - i}' for i in range(len(heatmap_data))]
ax.set_yticklabels(y_labels, rotation=0)
ax.set_xticklabels(ax.get_xticklabels(), rotation=45, ha='right')

plt.tight_layout()
plt.savefig('/Users/firecaster/OneDrive - The University of Melbourne/Documents/Chapter 2/Chapter 2 data/Stringybark/firebrands_heatmap.png', 
            dpi=300, bbox_inches='tight')
print("Firebrands heatmap saved to: firebrands_heatmap.png")

plt.show()

# Print summary
print("\nFirebrands Heatmap Summary:")
print(f"Total sections: {len(heatmap_data)}")
print(f"Trees: {list(heatmap_data.columns)}")
print(f"\nFirebrands count per tree:")
print(heatmap_data.sum())
