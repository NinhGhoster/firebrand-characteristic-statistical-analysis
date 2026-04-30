import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import matplotlib.patches as mpatches
import os

# --- Function to load a single dataset ---
def load_density_data(df, sheet_name):
    """
    Loads and processes density data from a specific sheet.
    Return clean Series or empty Series.
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
            # Outlier filtering removed as per latest user preference for these datasets
            # density_column = density_column[density_column <= 800] 
            
            if not density_column.empty:
                return density_column
    except Exception as e:
        print(f"Error processing {sheet_name}: {e}")
        
    return pd.Series([], dtype=float)

# --- Data Loading ---

# 1. Stringybark
sb_file = 'Stringybark/stringybark.xlsx'
sb_obliqua = pd.Series([], dtype=float)
sb_radiata = pd.Series([], dtype=float)

if os.path.exists(sb_file):
    try:
        xls_sb = pd.ExcelFile(sb_file)
        sb_obliqua = load_density_data(pd.read_excel(xls_sb, sheet_name="E  obliqua 0% char T5"), "E  obliqua 0% char T5")
        sb_radiata = load_density_data(pd.read_excel(xls_sb, sheet_name="E  radiata 0% char T8"), "E  radiata 0% char T8")
    except Exception as e:
        print(f"Error loading {sb_file}: {e}")
else:
    print(f"File not found: {sb_file}")

sb_total = pd.concat([sb_obliqua, sb_radiata], ignore_index=True)

# 2. Candlebark
cb_file = 'Candlebark/candlebark.xlsx'
candlebark_all = pd.Series([], dtype=float)

if os.path.exists(cb_file):
    try:
        xls_cb = pd.ExcelFile(cb_file)
        cb_list = []
        for sheet in xls_cb.sheet_names:
            data = load_density_data(pd.read_excel(xls_cb, sheet_name=sheet), sheet)
            if not data.empty:
                cb_list.append(data)
        
        if cb_list:
            candlebark_all = pd.concat(cb_list, ignore_index=True)
    except Exception as e:
        print(f"Error loading {cb_file}: {e}")
else:
    print(f"File not found: {cb_file}")

# 3. Grand Total
grand_total = pd.concat([sb_total, candlebark_all], ignore_index=True)

# --- Organize Data for Plotting ---
ordered_data_map = {
    "Stringybark\nE. obliqua": sb_obliqua,
    "Stringybark\nE. radiata": sb_radiata,
    "Combined\nStringybark": sb_total,
    "Candlebark": candlebark_all,
    "Combined\nall bark": grand_total
}

density_data = list(ordered_data_map.values())
labels = list(ordered_data_map.keys())

# --- Plotting ---
if any(not d.empty for d in density_data):
    plt.style.use('seaborn-v0_8-whitegrid')
    fig, ax = plt.subplots(figsize=(14, 8))

    # Boxplot
    boxplot = ax.boxplot(density_data,
                         notch=True,
                         patch_artist=True,
                         showmeans=True,
                         meanline=False,
                         showfliers=False,
                         widths=0.5)

    # Style: All White Boxes
    for patch in boxplot['boxes']:
        patch.set_facecolor('white')
        patch.set_edgecolor('black')
        patch.set_alpha(1.0) # Solid white

    # Style: Lines
    for element in ['whiskers', 'caps']:
        plt.setp(boxplot[element], color='black', linewidth=1.5)
    plt.setp(boxplot['medians'], color='black', linewidth=2)
    
    # Style: Means
    mean_marker = dict(markerfacecolor='red', markeredgecolor='black', marker='D', markersize=6)
    for mean_point in boxplot['means']:
        mean_point.set(**mean_marker)

    # Labels
    ax.set_ylabel('Density (kg/m³)', fontsize=14, fontweight='bold')
    ax.set_xlabel('Bark', fontsize=14, fontweight='bold')
    ax.set_xticklabels(labels, rotation=0, fontsize=11)
    ax.tick_params(axis='y', labelsize=11)
    
    # Grid
    ax.yaxis.grid(True, linestyle='--', alpha=0.7)
    ax.xaxis.grid(False)

    # Annotations (Mean/Median text)
    for i, (median_line, mean_point) in enumerate(zip(boxplot['medians'], boxplot['means'])):
        # Check if data exists
        if density_data[i].empty:
            continue
            
        median_val = median_line.get_ydata()[0]
        mean_val = mean_point.get_ydata()[0]
        
        # Position text to the right
        text_x_pos = i + 1.28
        
        mean_str = f"{int(round(mean_val))}"
        median_str = f"{int(round(median_val))}"
        
        ax.text(text_x_pos, mean_val, mean_str,
                horizontalalignment='left', verticalalignment='center',
                fontsize=9, color='red', fontweight='bold',
                bbox=dict(facecolor='white', alpha=0.6, edgecolor='none', pad=1))
        ax.text(text_x_pos, median_val, median_str,
                horizontalalignment='left', verticalalignment='center',
                fontsize=9, color='black', fontweight='bold',
                bbox=dict(facecolor='white', alpha=0.6, edgecolor='none', pad=1))

    # Legend
    legend_elements = [
        plt.Line2D([0], [0], color='black', linewidth=2, label='Median'),
        plt.Line2D([0], [0], marker='D', color='w', markerfacecolor='red', markeredgecolor='black', markersize=6, label='Mean')
    ]
    ax.legend(handles=legend_elements, loc='upper left', bbox_to_anchor=(1.02, 1), 
              fontsize=10, frameon=True, framealpha=0.9)

    plt.tight_layout()
    # Adjust for legend space
    plt.subplots_adjust(right=0.85)
    
    output_filename = "combined_bark_density_boxplot.png"
    plt.savefig(output_filename, dpi=300, bbox_inches='tight')
    print(f"Plot generated: {output_filename}")
    
    # --- Print Stats ---
    print("\n--- Statistics (Count, Mean, Std, etc.) ---")
    for name, data in ordered_data_map.items():
        print(f"\n{name.replace(chr(10), ' ')}:")
        if not data.empty:
            print(data.describe())
        else:
            print("No data.")

else:
    print("No valid density data found in any file.")
