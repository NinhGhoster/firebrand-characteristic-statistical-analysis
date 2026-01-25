# Import necessary libraries
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np # Import numpy for concatenating series
import matplotlib.patches as mpatches
import io

# --- Feature Toggle ---
# Set this to True to remove outliers, or False to keep and display them.
REMOVE_OUTLIERS = False

# --- Function to remove outliers ---
def remove_outliers(data_series):
    """
    Removes outliers from a pandas Series using the IQR method.
    """
    if data_series.empty:
        return data_series
    Q1 = data_series.quantile(0.25)
    Q3 = data_series.quantile(0.75)
    IQR = Q3 - Q1
    lower_bound = Q1 - 1.5 * IQR
    upper_bound = Q3 + 1.5 * IQR
    return data_series[(data_series >= lower_bound) & (data_series <= upper_bound)]

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
file_path = 'branchlet raw data.xlsx'
try:
    xls = pd.ExcelFile(file_path)
    
    # helper for concise loading
    def get_sheet_data(sheet):
        if sheet in xls.sheet_names:
            return load_density_data(pd.read_excel(xls, sheet_name=sheet), sheet)
        else:
            print(f"Sheet '{sheet}' not found.")
            return pd.Series([], dtype=float)

    leave_data_raw = get_sheet_data("leave")
    no_leave_branchlet_data_raw = get_sheet_data("no leave - branchlet")
    twigs_2_data_raw = get_sheet_data("twigs (2)")
    acacia_data_raw = get_sheet_data("Acacia")
    pine_data_raw = get_sheet_data("Pine")

except Exception as e:
    print(f"Error loading Excel file: {e}")
    exit()

# Conditionally remove outliers based on the toggle
if REMOVE_OUTLIERS:
    leave_data = remove_outliers(leave_data_raw)
    no_leave_branchlet_data = remove_outliers(no_leave_branchlet_data_raw)
    twigs_2_data = remove_outliers(twigs_2_data_raw)
    acacia_data = remove_outliers(acacia_data_raw)
    pine_data = remove_outliers(pine_data_raw)
else:
    leave_data = leave_data_raw
    no_leave_branchlet_data = no_leave_branchlet_data_raw
    twigs_2_data = twigs_2_data_raw
    acacia_data = acacia_data_raw
    pine_data = pine_data_raw

# Create Total category
total_data = pd.concat([leave_data, no_leave_branchlet_data, twigs_2_data, acacia_data, pine_data], ignore_index=True)

# --- Arrange Data and Labels in the correct order ---
ordered_data_map = {
    "Leave": leave_data,
    "No Leave - Branchlet": no_leave_branchlet_data,
    "Twigs (2)": twigs_2_data,
    "Acacia": acacia_data,
    "Pine": pine_data,
    "Total": total_data
}

density_data_for_boxplot = list(ordered_data_map.values())
short_labels_filtered = list(ordered_data_map.keys())

# --- Define Colors ---
euc_color = '#ff9999'
acacia_color = '#66b3ff'
pine_color = '#99ff99'
total_color = '#c2c2f0' # Light purple for Total

colors = [euc_color, euc_color, euc_color, acacia_color, pine_color, total_color]

# --- Plotting Code ---
if density_data_for_boxplot:
    fig, ax = plt.subplots(figsize=(16, 9))

    # Create a notched boxplot, showing/hiding outliers based on the setting
    boxplot = ax.boxplot(density_data_for_boxplot, notch=True, patch_artist=True, showmeans=True, meanline=False, showfliers=(not REMOVE_OUTLIERS))

    # Apply colors to the boxes
    for patch, color in zip(boxplot['boxes'], colors):
        patch.set_facecolor(color)

    # Set plot titles and labels
    # REMOVED TITLE as requested
    # ax.set_title(plot_title, fontsize=16)
    
    ax.set_ylabel('Density (kg/m³)', fontsize=12)
    ax.set_xlabel('Sample Source', fontsize=12)
    ax.yaxis.grid(True)

    # Set y-axis limits automatically
    # Combine all data to find max
    all_data = pd.concat(density_data_for_boxplot, ignore_index=True)
    if not all_data.empty:
        # You might want to adjust this limit based on your data range
        ax.set_ylim(0, 1000) 

    # Set the x-axis ticks and labels
    ax.set_xticks(range(1, len(short_labels_filtered) + 1))
    ax.set_xticklabels(short_labels_filtered, rotation=0, ha="center")

    # Customize median and mean markers
    mean_marker = dict(markerfacecolor='red', markeredgecolor='red', marker='D')
    for median in boxplot['medians']:
        median.set(color='black', linewidth=2)
    for mean_point in boxplot['means']:
        mean_point.set(**mean_marker)

    # Add text annotations with 3 significant digits
    for i, (median_line, mean_point) in enumerate(zip(boxplot['medians'], boxplot['means'])):
        if i >= len(density_data_for_boxplot): break # Safety check
        
        # Get data for this box
        data_series = density_data_for_boxplot[i]
        if data_series.empty: continue

        median_val = median_line.get_ydata()[0]
        mean_val = mean_point.get_ydata()[0]
        
        # Position the text to the right of the box
        text_x_pos = i + 1.1 # Closer to the box
        
        # Use '.3g' to format to 3 significant figures
        try:
             ax.text(text_x_pos, median_val, f'{median_val:.3g}',
                    verticalalignment='center', size='small', color='black', weight='semibold',
                    bbox=dict(facecolor='white', alpha=0.6, edgecolor='none', boxstyle='round,pad=0.2'))

             ax.text(text_x_pos, mean_val, f' {mean_val:.3g}',
                    verticalalignment='bottom', size='small', color='red', weight='semibold',
                    bbox=dict(facecolor='white', alpha=0.6, edgecolor='none', boxstyle='round,pad=0.2'))
        except (IndexError, ValueError):
            pass


    # Legend Setup
    mean_proxy = plt.Line2D([0], [0], marker='D', color='w', label='Mean',
                              markerfacecolor='red', markersize=8)
    median_proxy = plt.Line2D([0], [0], color='black', lw=2, label='Median')

    # Custom Legend for Species
    euc_patch = mpatches.Patch(color=euc_color, label='Eucalyptus')
    acacia_patch = mpatches.Patch(color=acacia_color, label='Acacia')
    pine_patch = mpatches.Patch(color=pine_color, label='Pine')
    
    legend_handles = [median_proxy, mean_proxy, euc_patch, acacia_patch, pine_patch]

    legend1 = ax.legend(handles=legend_handles, loc='upper right', bbox_to_anchor=(1, 1))
    ax.add_artist(legend1)

    plt.tight_layout(rect=[0, 0, 1, 0.96])
    plt.savefig("density_boxplot_groups.png")
    # plt.show() # Commented out for headless environment script execution if needed

    # Print Statistics
    stats_title = "\n--- Statistics for Density"
    if REMOVE_OUTLIERS:
        stats_title += " (Outliers Removed)"
    stats_title += " ---"
    print(stats_title)
    
    for label, data in ordered_data_map.items():
        print(f"\n{label}:")
        if not data.empty:
            print(data.describe())
        else:
            print("No data available.")
else:
    print("No valid density data found in any of the provided files to generate a boxplot.")
