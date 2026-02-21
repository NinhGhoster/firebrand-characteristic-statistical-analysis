import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import matplotlib.patches as mpatches

# --- Function to load a single dataset ---
def load_density_data(df, sheet_name):
    """
    Loads and processes density data from a specific sheet in the Excel file.
    """
    try:
        # Check if column exists
        density_col_name = None
        if 'Density (kg/m3)' in df.columns:
            density_col_name = 'Density (kg/m3)'
        elif 'Density (kg.m3)' in df.columns:
            density_col_name = 'Density (kg.m3)'
            
        if density_col_name:
            density_column = df[density_col_name].dropna()
            
            # Remove outliers > 800 as per user request
            density_column = density_column[density_column <= 800]

            if not density_column.empty:
                return density_column
            else:
                print(f"'{density_col_name}' column in {sheet_name} is empty.")
        else:
            print(f"Density column not found in {sheet_name}.")
    except Exception as e:
        print(f"An error occurred while processing {sheet_name}: {e}")
    return pd.Series([], dtype=float)


# --- Data Loading and Preparation ---
# Load from Excel file
file_path = 'stringybark.xlsx'
try:
    xls = pd.ExcelFile(file_path)
    
    # helper for concise loading
    def get_sheet_data(sheet):
        if sheet in xls.sheet_names:
            return load_density_data(pd.read_excel(xls, sheet_name=sheet), sheet)
        else:
            print(f"Sheet '{sheet}' not found.")
            return pd.Series([], dtype=float)

    # Load data from the two relevant sheets
    obliqua_0_char = get_sheet_data("E  obliqua 0% char T5")
    radiata_0_char = get_sheet_data("E  radiata 0% char T8")

except Exception as e:
    print(f"Error loading Excel file: {e}")
    exit()

# If both are empty, exit
if obliqua_0_char.empty and radiata_0_char.empty:
    print("No valid data found in the specified sheets.")
    exit()

# Create Total category
total_data = pd.concat([obliqua_0_char, radiata_0_char], ignore_index=True)

# --- Arrange Data and Labels ---
ordered_data_map = {
    "E. obliqua": obliqua_0_char,
    "E. radiata": radiata_0_char,
    "Total": total_data
}

density_data_for_boxplot = list(ordered_data_map.values())
labels = list(ordered_data_map.keys())

# --- Define Colors ---
# All white as per request
colors = ['white', 'white', 'white']

# --- Plotting Code ---
if density_data_for_boxplot:
    # Improve design: Aspect ratio and style
    plt.style.use('seaborn-v0_8-whitegrid')
    fig, ax = plt.subplots(figsize=(10, 8)) 

    # Create notched boxplot
    boxplot = ax.boxplot(density_data_for_boxplot, 
                         notch=True, 
                         patch_artist=True, 
                         showmeans=True, 
                         meanline=False, 
                         showfliers=False,
                         widths=0.5)

    # Apply colors
    for i, patch in enumerate(boxplot['boxes']):
        patch.set_facecolor(colors[i])
        patch.set_edgecolor('black')
        patch.set_alpha(0.8)

    # Customizing elements
    for element in ['whiskers', 'caps']:
        plt.setp(boxplot[element], color='black', linewidth=1.5)
    plt.setp(boxplot['medians'], color='black', linewidth=2)
    
    # Mean markers
    mean_marker = dict(markerfacecolor='red', markeredgecolor='black', marker='D', markersize=6)
    for mean_point in boxplot['means']:
        mean_point.set(**mean_marker)

    # Labels
    ax.set_ylabel('Density (kg/m³)', fontsize=14, fontweight='bold')
    ax.set_xlabel('Species', fontsize=14, fontweight='bold')
    ax.set_xticks(range(1, len(labels) + 1))
    ax.set_xticklabels(labels, rotation=0, fontsize=11)
    ax.tick_params(axis='y', labelsize=11)

    ax.yaxis.grid(True, linestyle='--', alpha=0.7)
    ax.xaxis.grid(False)

    # --- Annotations ---
    for i, (median_line, mean_point) in enumerate(zip(boxplot['medians'], boxplot['means'])):
        median_val = median_line.get_ydata()[0]
        mean_val = mean_point.get_ydata()[0]
        
        # Position text to the right of the box
        text_x_pos = i + 1.3
        ha = 'left'
            
        mean_str = f"{int(round(mean_val))}"
        median_str = f"{int(round(median_val))}"
        
        ax.text(text_x_pos, mean_val, mean_str,
                horizontalalignment=ha, verticalalignment='center',
                fontsize=9, color='red', fontweight='bold',
                bbox=dict(facecolor='white', alpha=0.6, edgecolor='none', pad=1))
        ax.text(text_x_pos, median_val, median_str,
                horizontalalignment=ha, verticalalignment='center',
                fontsize=9, color='black', fontweight='bold',
                bbox=dict(facecolor='white', alpha=0.6, edgecolor='none', pad=1))

    # --- LEGEND ---
    legend_elements = [
        plt.Line2D([0], [0], color='black', linewidth=2, label='Median'),
        plt.Line2D([0], [0], marker='D', color='w', markerfacecolor='red', markeredgecolor='black', markersize=6, label='Mean')
    ]
    
    ax.legend(handles=legend_elements, loc='upper left', bbox_to_anchor=(1.02, 1), 
              fontsize=10, frameon=True, framealpha=0.9)

    plt.tight_layout()
    plt.subplots_adjust(right=0.82)
    
    plt.savefig("stringybark_density_boxplot.png", dpi=300, bbox_inches='tight')
    print("Plot generated: stringybark_density_boxplot.png")

# Print Statistics
print("\n--- Statistics for Stringybark Density ---")
for label, data in ordered_data_map.items():
    print(f"\n{label}:") 
    if not data.empty:
        print(data.describe())

else:
    print("No valid density data found.")
