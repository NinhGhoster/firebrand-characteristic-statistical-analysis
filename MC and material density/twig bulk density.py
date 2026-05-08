import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from matplotlib.lines import Line2D

# Set global font sizes — MATCHING twigs MC.py standard
plt.rcParams.update({'font.size': 14, 'axes.labelsize': 16, 'xtick.labelsize': 14, 'ytick.labelsize': 14, 'legend.fontsize': 14, 'axes.titlesize': 16})

# Load the dataset
df = pd.read_csv("twig bulk density.csv")

# Extract species name
df['Species'] = df['File (ID)'].apply(lambda x: x.split()[0])

# Calculate Material Density in kg/m^3
df[r'Material Density (kg/m3)'] = (df['Dried mass (g)'] / df['Volume (mm3)']) * 1e6

# Define order and colors
species_order = ["Eucalyptus", "Acacia", "Pine"]
species_colors = {
    "Eucalyptus": "#1f77b4",  # Blue
    "Pine": "#2ca02c",        # Green
    "Acacia": "#ff7f0e"       # Orange
}

# --- Define Mean and Median properties ---
median_color = 'magenta'
mean_color = 'red'

my_median_props = dict(color=median_color, linewidth=2)
my_mean_props = dict(marker='D', markersize=6, 
                     markeredgecolor=mean_color, 
                     markerfacecolor=mean_color)

# Plotting — MATCHING twigs MC.py standard figsize
fig, ax = plt.subplots(figsize=(6, 6))

# Boxplot with custom width
sns.boxplot(
    ax=ax,
    x='Species', 
    y=r'Material Density (kg/m3)', 
    hue='Species', 
    data=df, 
    order=species_order, 
    palette=species_colors, 
    notch=True,
    width=0.35,
    showmeans=True,
    meanline=False,
    medianprops=my_median_props,
    meanprops=my_mean_props
)

# Remove the default hue legend if it appears
if ax.get_legend():
    ax.get_legend().remove()

# Add individual data points (Strip plot)
sns.stripplot(
    ax=ax,
    x='Species', 
    y=r'Material Density (kg/m3)', 
    data=df, 
    order=species_order, 
    color='black', 
    alpha=0.5
)

# --- Create Custom Legend ---
legend_elements = [
    Line2D([], [], color=median_color, lw=2, label='Median'),
    Line2D([], [], marker='D', color='w', label='Mean',
           markerfacecolor=mean_color, markeredgecolor=mean_color, markersize=8)
]

ax.legend(handles=legend_elements, loc='upper right')

ax.set_xlabel('Species', fontsize=16)
ax.set_ylabel(r'Material Density ($\mathrm{kg/m^3}$)', fontsize=16)
ax.yaxis.grid(True, linestyle='--', alpha=0.7)
ax.set_axisbelow(True)

plt.tight_layout()
plt.savefig('twig material density.png', dpi=150)