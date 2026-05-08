import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import matplotlib.patches as mpatches

# Set global font sizes to be larger
plt.rcParams.update({'font.size': 14, 'axes.labelsize': 16, 'xtick.labelsize': 14, 'ytick.labelsize': 14, 'legend.fontsize': 14, 'axes.titlesize': 16})

# --- 1. Data Definition ---

# Dataset 1: Eucalyptus
euc_c1 = [100.7428807, 131.5463004, 113.6172007]
euc_c2 = [90.76660988, 104.3715847, 93.00095877]
euc_c3 = [85.50091912, 60.78118772, 85.12041284]
euc_c4 = [123.4478602, 113.6815394, 101.8180198] # leave

# Dataset 2: Pine
pine_c1 = [116.3636364, 110.8231707, 118.5687847]
pine_c2 = [112.0032773, 59.58029197, 118.8222345]
pine_c3 = [111.4489311, 106.7766647, 121.5669014]
pine_c4 = [134.8233067, 138.6684159, 139.6929029] # leave

# Dataset 3: Acacia
acacia_c1 = [102.2556391, 97.51580849, 99.57706767]
acacia_c2 = [84.16833667, 88.06598807, 96.96641387]
acacia_c3 = [89.41441441, 78.69451697, 97.79553596]
acacia_c4 = [109.5974618, 110.3225806, 115.3857225] # leave

# --- 2. Data Processing ---

def process_dataset(c1, c2, c3, c4):
    """Takes C1-C4 data and returns a list containing C1, C2, C3, C4, T4, and T5."""
    t4 = c1 + c2 + c3       # Total without leave
    t5 = c1 + c2 + c3 + c4  # Total with leave
    return [c1, c2, c3, c4, t4, t5]

eucalyptus_data = process_dataset(euc_c1, euc_c2, euc_c3, euc_c4)
pine_data = process_dataset(pine_c1, pine_c2, pine_c3, pine_c4)
acacia_data = process_dataset(acacia_c1, acacia_c2, acacia_c3, acacia_c4)

all_datasets = [eucalyptus_data, pine_data, acacia_data]
dataset_labels = ['Eucalyptus', 'Pine', 'Acacia']
dataset_colors = ['#1f77b4', '#2ca02c', '#ff7f0e'] # Blue, Green, Orange
category_labels = ['C1', 'C2', 'C3', 'C4', 'T4', 'T5']

# --- 3. PRINT STATISTICS TO TERMINAL ---

print(f"{'Species':<12} | {'Category':<10} | {'Mean':<10} | {'Median':<10}")
print("-" * 50)

for species_name, dataset in zip(dataset_labels, all_datasets):
    for cat_name, data_points in zip(category_labels, dataset):
        mean_val = np.mean(data_points)
        median_val = np.median(data_points)
        print(f"{species_name:<12} | {cat_name:<10} | {mean_val:<10.2f} | {median_val:<10.2f}")
    print("-" * 50)

# --- 4. Plotting Setup ---

category_patterns = ['/', '\\', 'x', 'o', '+', '*']

fig, ax = plt.subplots(figsize=(12, 6))
n_datasets = len(all_datasets)
n_categories = len(category_labels)
box_width = 0.25
base_positions = np.arange(1, n_categories + 1)

# --- 5. Plotting with Notched Boxplots ---

median_color = 'magenta'
mean_color = 'red'

for i, dataset_data in enumerate(all_datasets):
    offset = (i - (n_datasets - 1) / 2) * box_width
    positions = base_positions + offset
    
    # ADDED notch=True here
    bp = ax.boxplot(dataset_data,
                    positions=positions,
                    widths=box_width,
                    patch_artist=True,
                    notch=True,        # <--- Request: Notched boxplot
                    showmeans=True,
                    meanline=False,
                    medianprops=dict(color=median_color, linewidth=2),
                    meanprops=dict(marker='D', markersize=6, markeredgecolor=mean_color, markerfacecolor=mean_color))

    # Apply colors and patterns to each box
    for j, patch in enumerate(bp['boxes']):
        patch.set_facecolor(dataset_colors[i])
        patch.set_hatch(category_patterns[j])
        patch.set_edgecolor('black')

# --- 6. Plot Customization and Consolidated Legend ---

ax.set_ylabel('MC (%)', fontsize=16)
ax.set_xlabel('Sample Category', fontsize=16)
ax.set_xticks(base_positions)
ax.set_xticklabels(category_labels)
ax.tick_params(axis='x', labelsize=14)
ax.yaxis.grid(True, linestyle='--', alpha=0.7)
ax.set_axisbelow(True)

# --- Create the Consolidated Legend ---

# Handles for Species
species_handles = [mpatches.Patch(color=color, label=label) for color, label in zip(dataset_colors, dataset_labels)]

# Handles for Categories
category_details = [
    "C1: 10 - 20 mm", 
    "C2: 5 - 10 mm", 
    "C3: 0 - 5 mm",
    "C4: leave", 
    "T4 = C1 + C2 + C3", 
    "T5 = C1 + C2 + C3 + C4"
]
category_handles = [mpatches.Patch(facecolor='white', edgecolor='black', hatch=pattern, label=label)
                    for pattern, label in zip(category_patterns, category_details)]

# Handles for Box Elements
element_handles = [
    plt.Line2D([], [], color=median_color, lw=2, label='Median'),
    plt.Line2D([], [], marker='D', color='w', label='Mean',
               markerfacecolor=mean_color, markeredgecolor=mean_color, markersize=8)
]

all_handles = species_handles + category_handles + element_handles

ax.legend(handles=all_handles,
          loc='lower left',
          bbox_to_anchor=(0.01, 0.01),
          fontsize=9,
          ncol=1,
          labelspacing=0.2,
          framealpha=0.9)

plt.tight_layout()
plt.savefig('twigs MC notched.png', dpi=150)