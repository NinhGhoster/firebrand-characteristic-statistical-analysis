import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import matplotlib.patches as mpatches
import re

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
            
            # Outlier filtering removed as per user request
            # density_column = density_column[density_column <= 800]

            if not density_column.empty:
                return density_column
            else:
                pass # Silent skip for empty filtered data
        else:
            pass # Silent skip for sheets without density
    except Exception as e:
        print(f"An error occurred while processing {sheet_name}: {e}")
    return pd.Series([], dtype=float)


# --- Data Loading and Preparation ---
file_path = 'candlebark.xlsx'
try:
    xls = pd.ExcelFile(file_path)
    
    flat_series_list = []
    curve_series_list = []

    for sheet_name in xls.sheet_names:
        # User rule: "sheets name without auto has density only" 
        # and "If there is a firebrand doesn't have density, then exclude it"
        # We rely on load_density_data to check for density column existence.
        
        # We also implicitly filter out _AUTO if they don't have density (which they likely don't).
        
        data = load_density_data(pd.read_excel(xls, sheet_name=sheet_name), sheet_name)
        
        if not data.empty:
            if "Flat" in sheet_name:
                flat_series_list.append(data)
            elif "Curve" in sheet_name:
                curve_series_list.append(data)
            else:
                print(f"Sheet '{sheet_name}' matched neither Flat nor Curve category.")

    # Concatenate
    flat_data = pd.concat(flat_series_list, ignore_index=True) if flat_series_list else pd.Series([], dtype=float)
    curve_data = pd.concat(curve_series_list, ignore_index=True) if curve_series_list else pd.Series([], dtype=float)
    total_data = pd.concat([flat_data, curve_data], ignore_index=True)

except Exception as e:
    print(f"Error loading Excel file: {e}")
    exit()

# If all empty
if flat_data.empty and curve_data.empty:
    print("No valid density data found in any sheet.")
    exit()

# --- Arrange Data and Labels ---
if curve_data.empty:
    # "If there is no Curve then, remove curve and total, name in the x axis should be 'Candlebark' only."
    ordered_data_map = {
        "Candlebark": flat_data
    }
    # Adjust colors list to match 1 item
    colors = ['white']
else:
    ordered_data_map = {
        "Flat": flat_data,
        "Curve": curve_data,
        "Total": total_data
    }
    colors = ['white', 'white', 'white']

density_data_for_boxplot = list(ordered_data_map.values())
labels = list(ordered_data_map.keys())

# --- Define Colors ---
# White as per "same thing" (referring to the latest Stringybark update)
colors = ['white', 'white', 'white']

# --- Plotting Code ---
if density_data_for_boxplot:
    # Improve design: Aspect ratio and style
    plt.style.use('seaborn-v0_8-whitegrid')
    
    # Adaptive figure size: narrower if only 1 category
    n_cats = len(density_data_for_boxplot)
    fig_width = 6 if n_cats == 1 else 10
    
    fig, ax = plt.subplots(figsize=(fig_width, 8)) 

    # Create notched boxplot
    # Note: If a dataset is empty (like Curve might be), boxplot can handle it but won't draw a box.
    boxplot = ax.boxplot(density_data_for_boxplot, 
                         notch=True, 
                         patch_artist=True, 
                         showmeans=True, 
                         meanline=False, 
                         showfliers=False,
                         widths=0.4)

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
    ax.set_xlabel('Candlebark', fontsize=14, fontweight='bold')
    ax.set_xticks(range(1, len(labels) + 1))
    ax.set_xticklabels([''] * len(labels)) # Remove tick labels as per request
    ax.tick_params(axis='y', labelsize=11)

    ax.yaxis.grid(True, linestyle='--', alpha=0.7)
    ax.xaxis.grid(False)

    # --- Annotations ---
    for i, (median_line, mean_point) in enumerate(zip(boxplot['medians'], boxplot['means'])):
        # Check if data exists for this box
        msg_data = density_data_for_boxplot[i]
        if msg_data.empty:
            continue

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
    
    plt.savefig("candlebark_density_boxplot.png", dpi=300, bbox_inches='tight')
    print("Plot generated: candlebark_density_boxplot.png")

# Print Statistics
print("\n--- Statistics for Candlebark Density ---")
for label, data in ordered_data_map.items():
    print(f"\n{label}:") 
    if not data.empty:
        print(data.describe())
    else:
        print("No valid data.")
