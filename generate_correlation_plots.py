import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from scipy.stats import pearsonr
import os

def calculate_pvalues(df):
    df = df.dropna()._get_numeric_data()
    dfcols = pd.DataFrame(columns=df.columns)
    pvalues = dfcols.transpose().join(dfcols, how='outer')
    for r in df.columns:
        for c in df.columns:
            if r == c:
                pvalues[r][c] = 0.0
            else:
                pvalues[r][c] = pearsonr(df[r], df[c])[1]
    return pvalues

def get_stars(p):
    if p < 0.001:
        return '***'
    elif p < 0.01:
        return '**'
    elif p < 0.05:
        return '*'
    else:
        return ''

def plot_correlogram(ax, df, title):
    # Calculate correlations and p-values
    corr = df.corr()
    pvals = calculate_pvalues(df)
    
    # Create mask for upper triangle (excluding diagonal)
    mask = np.triu(np.ones_like(corr, dtype=bool), k=1)
    
    # Generate annotations (value + stars)
    annot = np.empty_like(corr, dtype=object)
    for i in range(corr.shape[0]):
        for j in range(corr.shape[1]):
            if mask[i, j]:
                annot[i, j] = ''
            else:
                val = corr.iloc[i, j]
                p = pvals.iloc[i, j]
                stars = get_stars(p)
                annot[i, j] = f"{val:.2f}{stars}"
                
    # Plot heatmap
    sns.heatmap(corr, mask=mask, annot=annot, fmt='', cmap='RdBu_r', 
                vmin=-1, vmax=1, center=0, square=True, 
                linewidths=.5, cbar_kws={"shrink": .8}, ax=ax,
                annot_kws={"size": 10})
    
    ax.set_title(title, fontsize=14, pad=25)
    
    # Capitalize labels
    labels = [c.replace('_', ' ').title() for c in corr.columns]
    
    # Move x-axis labels to top
    ax.xaxis.tick_top()
    ax.set_xticklabels(labels, rotation=45, ha='left')
    ax.set_yticklabels(labels, rotation=0)

# Load datasets
base_path = '/Users/firecaster/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Documents/Chapter 2/Chapter 2 data/'

# 1. Branchlet
bp = os.path.join(base_path, 'Branchlet', 'branchlet raw data.xlsx')
b_sheets = ['leave', 'no leave - branchlet', 'twigs (2)']
df_b = pd.concat([pd.read_excel(bp, sheet_name=s) for s in b_sheets])
df_b.rename(columns={'Volume (mm3)': 'volume', 'Surface Area (mm2)': 'surface_area', 
                     'Length (mm)': 'length', 'Width (mm)': 'width', 
                     'Height (mm)': 'height', 'Mass (g)': 'mass'}, inplace=True)
df_b['vol_sa_ratio'] = df_b['volume'] / df_b['surface_area']
agg_b = df_b.groupby('Source.Name').agg(
    count=('length', 'count'),
    length=('length', 'mean'),
    width=('width', 'mean'),
    height=('height', 'mean'),
    mass=('mass', 'mean'),
    surface_area=('surface_area', 'mean'),
    volume=('volume', 'mean'),
    vol_sa_ratio=('vol_sa_ratio', 'mean')
).dropna()

# 2. Stringybark
sp = os.path.join(base_path, 'Stringybark', 'stringybark.xlsx')
s_sheets = ['E  obliqua 0% char T5', 'E  obliqua 10-50% char T9', 'E  obliqua 50-90% char T16', 'E  obliqua 90% char T17', 'E  radiata 0% char T8']
df_s = pd.concat([pd.read_excel(sp, sheet_name=s) for s in s_sheets])
df_s.rename(columns={'Volume (mm3)': 'volume', 'Surface Area (mm2)': 'surface_area', 
                     'Length (mm)': 'length', 'Width (mm)': 'width', 
                     'Height (mm)': 'height', 'Mass (g)': 'mass'}, inplace=True)
df_s['vol_sa_ratio'] = df_s['volume'] / df_s['surface_area']
agg_s = df_s.groupby('Source.Name').agg(
    count=('length', 'count'),
    length=('length', 'mean'),
    width=('width', 'mean'),
    height=('height', 'mean'),
    mass=('mass', 'mean'),
    surface_area=('surface_area', 'mean'),
    volume=('volume', 'mean'),
    vol_sa_ratio=('vol_sa_ratio', 'mean')
).dropna()

# 3. Candlebark
cp = os.path.join(base_path, 'Candlebark', 'candlebark.xlsx')
xls_c = pd.ExcelFile(cp)
c_sheets = [s for s in xls_c.sheet_names if '_AUTO' not in s]
df_c = pd.concat([pd.read_excel(cp, sheet_name=s) for s in c_sheets])
df_c.rename(columns={'Volume (mm3)': 'volume', 'Surface Area (mm2)': 'surface_area', 
                     'Length (mm)': 'length', 'Width (mm)': 'width', 
                     'Height (mm)': 'height', 'Mass (g)': 'mass'}, inplace=True)
df_c['vol_sa_ratio'] = df_c['volume'] / df_c['surface_area']
agg_c = df_c.groupby('Source.Name').agg(
    count=('length', 'count'),
    length=('length', 'mean'),
    width=('width', 'mean'),
    height=('height', 'mean'),
    mass=('mass', 'mean'),
    surface_area=('surface_area', 'mean'),
    volume=('volume', 'mean'),
    vol_sa_ratio=('vol_sa_ratio', 'mean')
).dropna()

# Create figure
fig, axes = plt.subplots(1, 3, figsize=(22, 6))

plot_correlogram(axes[0], agg_b, 'Branchlet')
plot_correlogram(axes[1], agg_s, 'Stringybark')
plot_correlogram(axes[2], agg_c, 'Candlebark')

plt.tight_layout()
out_path = os.path.join(base_path, 'correlation_matrices.png')
plt.savefig(out_path, dpi=300, bbox_inches='tight')
print(f"Plot saved to {out_path}")
