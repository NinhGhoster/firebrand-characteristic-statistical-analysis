import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D # Import Line2D for custom legend
import seaborn as sns
import numpy as np
import sys # Import sys to allow exiting the script

# Set global font sizes to be larger
plt.rcParams.update({'font.size': 14, 'axes.labelsize': 16, 'xtick.labelsize': 14, 'ytick.labelsize': 14, 'legend.fontsize': 14, 'axes.titlesize': 16})

# --- 1. Load and Process NEW Data ---
file_path = 'candle bark density.csv' 

try:
    df = pd.read_csv(file_path)
except FileNotFoundError:
    print(f"ERROR: Cannot find the file '{file_path}'.")
    sys.exit() # Stop the script

# Rename columns for easier access
df.rename(columns={
    'Volume (mm3)': 'Volume_mm3',
    'Fresh mass (g)': 'Fresh_Mass_g',
    'Dried mass (g)': 'Dried_Mass_g'
}, inplace=True)

# Find rows with missing critical data
missing_volume = df['Volume_mm3'].isna()
missing_fresh = df['Fresh_Mass_g'].isna()
missing_dried = df['Dried_Mass_g'].isna()

critical_missing = df[missing_volume | missing_fresh | missing_dried]

if not critical_missing.empty:
    df.dropna(subset=['Volume_mm3', 'Fresh_Mass_g', 'Dried_Mass_g'], inplace=True)

# --- 3. Process Data ---
# Extract 'Sample Type' (Curve or Flat) from 'File (ID)'
df['Sample Type'] = df['File (ID)'].str.extract(r'^(Curve|Flat)')
df['Sample Type'] = df['Sample Type'].replace('Curve', 'Cylindrical')

# Calculate MC (%)
df['MC (%)'] = 100 * (df['Fresh_Mass_g'] - df['Dried_Mass_g']) / df['Fresh_Mass_g']

# Calculate Densities in g/mm3 first
fresh_density_g_mm3 = df['Fresh_Mass_g'] / df['Volume_mm3']
bulk_density_g_mm3 = df['Dried_Mass_g'] / df['Volume_mm3']

# Conversion factor: 1 g/mm³ = 1,000,000 kg/m³
conversion_factor = 1_000_000
df['Fresh Density (kg/m3)'] = fresh_density_g_mm3 * conversion_factor
df['Bulk Density (kg/m3)'] = bulk_density_g_mm3 * conversion_factor

# --- 4. Define Custom Plot Styles & Legend ---
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
           markerfacecolor='cyan', markeredgecolor='black', markersize=8),
    Line2D([0], [0], marker='.', color='black', label='Data point', 
           linestyle='None', markersize=8)
]

# --- 5. Create FIGURE 1 (Main Plot: Material Density & MC) ---
fig1, axes1 = plt.subplots(nrows=1, ncols=2, figsize=(10, 6))

sns.boxplot(ax=axes1[0], data=df, x='Sample Type', y='Bulk Density (kg/m3)', 
            order=['Flat', 'Cylindrical'], notch=True, width=0.5,
            showmeans=True, medianprops=medianprops, meanprops=meanprops)
sns.stripplot(ax=axes1[0], data=df, x='Sample Type', y='Bulk Density (kg/m3)', 
              order=['Flat', 'Cylindrical'], color='black', alpha=0.7, jitter=0.1)
axes1[0].set_title('Material Density')
axes1[0].set_ylabel(r'Material Density ($\mathrm{kg/m^3}$)')
axes1[0].set_xlabel('Sample Type')
axes1[0].grid(True, linestyle='--', alpha=0.6)
axes1[0].legend(handles=legend_elements, loc='upper left')

sns.boxplot(ax=axes1[1], data=df, x='Sample Type', y='MC (%)', 
            order=['Flat', 'Cylindrical'], notch=True, width=0.5,
            showmeans=True, medianprops=medianprops, meanprops=meanprops)
sns.stripplot(ax=axes1[1], data=df, x='Sample Type', y='MC (%)', 
              order=['Flat', 'Cylindrical'], color='black', alpha=0.7, jitter=0.1)
axes1[1].set_title('MC')
axes1[1].set_ylabel('MC (%)')
axes1[1].set_xlabel('Sample Type')
axes1[1].grid(True, linestyle='--', alpha=0.6)
axes1[1].legend(handles=legend_elements, loc='upper left')

plt.tight_layout()
plt.savefig('candle_bark_main_plot.png', dpi=150)
plt.close(fig1)

# --- 6. Create FIGURE 2 (Appendix Plot: Fresh Density) ---
fig2, ax2 = plt.subplots(nrows=1, ncols=1, figsize=(6, 6))

sns.boxplot(ax=ax2, data=df, x='Sample Type', y='Fresh Density (kg/m3)', 
            order=['Flat', 'Cylindrical'], notch=True, width=0.5,
            showmeans=True, medianprops=medianprops, meanprops=meanprops)
sns.stripplot(ax=ax2, data=df, x='Sample Type', y='Fresh Density (kg/m3)', 
              order=['Flat', 'Cylindrical'], color='black', alpha=0.7, jitter=0.1)
ax2.set_title('Fresh Density')
ax2.set_ylabel(r'Fresh Density ($\mathrm{kg/m^3}$)')
ax2.set_xlabel('Sample Type')
ax2.grid(True, linestyle='--', alpha=0.6)
ax2.legend(handles=legend_elements)

plt.tight_layout()
plt.savefig('candle_bark_appendix_plot.png', dpi=150)
plt.close(fig2)