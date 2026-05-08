import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D # Import Line2D for custom legend
import seaborn as sns
import sys

# Set global font sizes to be larger
plt.rcParams.update({'font.size': 14, 'axes.labelsize': 16, 'xtick.labelsize': 14, 'ytick.labelsize': 14, 'legend.fontsize': 14, 'axes.titlesize': 16})

# --- Define Custom Plot Styles & Legend ---
medianprops = {'color': 'orange', 'linewidth': 2.5}
meanprops = {
    'marker':'^',
    'markerfacecolor':'cyan',
    'markeredgecolor':'black',
    'markersize':8
}

legend_elements = [
    Line2D([0], [0], color='orange', lw=2.5, label='Median'),
    Line2D([0], [0], marker='^', color='w', label='Mean',
           markerfacecolor='cyan', markeredgecolor='black', markersize=8)
]

# --- 1. Load and Process Data ---
file_path_new = 'stringybark bulk density.csv'

try:
    df = pd.read_csv(file_path_new)
except FileNotFoundError:
    print(f"ERROR: Cannot find '{file_path_new}'. Make sure it is in the same folder.")
    sys.exit()

expected_cols = {
    'Volume (mm3)': 'Volume_mm3',
    'Fresh mass (g)': 'Fresh_Mass_g',
    'Dried mass (g)': 'Dried_Mass_g',
}
df.rename(columns={k: v for k, v in expected_cols.items() if k in df.columns}, inplace=True)

# Calculate Densities
df[r'Material Density (kg/m3)'] = (df['Dried_Mass_g'] / df['Volume_mm3']) * 1e6
df[r'Fresh Density (kg/m3)'] = (df['Fresh_Mass_g'] / df['Volume_mm3']) * 1e6
df['MC (%)'] = ((df['Fresh_Mass_g'] - df['Dried_Mass_g']) / df['Dried_Mass_g']) * 100

if 'Tree' not in df.columns:
    if 'File (ID)' in df.columns:
        df['Tree'] = df['File (ID)'].apply(lambda x: x.split('S')[0])
    else:
        sys.exit()

tree_to_group = {
    'T8': 'E. radiata\nextreme',
    'T5': 'E. obliqua\nextreme',
    'T9': 'E. obliqua\nvery high',
    'T16': 'E. obliqua\nhigh',
    'T17': 'E. obliqua\nmoderate'
}
df['Group'] = df['Tree'].map(tree_to_group)
group_order = ['E. radiata\nextreme', 'E. obliqua\nextreme', 'E. obliqua\nvery high', 'E. obliqua\nhigh', 'E. obliqua\nmoderate']

# --- 5. Create FIGURE 1 (Main Plot: MC & Material Density) ---
fig1, axes1 = plt.subplots(nrows=2, ncols=1, figsize=(10, 10), sharex=True)

sns.boxplot(ax=axes1[0], data=df, x='Group', y='MC (%)',
            order=group_order, notch=True, width=0.5,
            showmeans=True, medianprops=medianprops, meanprops=meanprops)
axes1[0].set_ylabel('MC (%)')
axes1[0].set_xlabel('')
axes1[0].grid(True, linestyle='--', alpha=0.6)
axes1[0].legend(handles=legend_elements)

sns.boxplot(ax=axes1[1], data=df, x='Group', y=r'Material Density (kg/m3)',
            order=group_order, notch=True, width=0.5,
            showmeans=True, medianprops=medianprops, meanprops=meanprops)
axes1[1].set_ylabel(r'Material Density ($\mathrm{kg/m^3}$)')
axes1[1].set_xlabel('Tree with Hazard Rating')
axes1[1].grid(True, linestyle='--', alpha=0.6)
axes1[1].legend(handles=legend_elements)

plt.tight_layout()
plt.savefig('stringybark_main_plot.png', dpi=150)
plt.close(fig1)

# --- 6. Create FIGURE 2 (Appendix Plot: Fresh Density) ---
fig2, ax2 = plt.subplots(nrows=1, ncols=1, figsize=(10, 6))

sns.boxplot(ax=ax2, data=df, x='Group', y=r'Fresh Density (kg/m3)',
            order=group_order, notch=True, width=0.5,
            showmeans=True, medianprops=medianprops, meanprops=meanprops)
ax2.set_ylabel(r'Fresh Density ($\mathrm{kg/m^3}$)')
ax2.set_xlabel('Tree with Hazard Rating')
ax2.grid(True, linestyle='--', alpha=0.6)
ax2.legend(handles=legend_elements)

plt.tight_layout()
plt.savefig('stringybark_appendix_plot.png', dpi=150)
plt.close(fig2)