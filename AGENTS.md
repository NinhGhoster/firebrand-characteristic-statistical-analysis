# Agent Context for Chapter 2 Data Analysis

## Project Overview
Firebrand morphology data analysis for Chapter 2 of a thesis. Three fuel types (Branchlet, Stringybark, Candlebark) analyzed for physical properties: dimensions, mass, density, volume-to-surface-area ratio (V/Sa), and firebrand counts under varying conditions.

## Environment
- **Conda**: `stas_test` (pandas, openpyxl, matplotlib, scipy)
- **R**: glmmTMB, emmeans, mgcv, MASS, ggplot2
- **Run Python**: `python3 script.py`
- **Run R**: `Rscript script.R`

## Project Structure
- **Branchlet/** — Raw data (`branchlet raw data.xlsx`), R statistical analysis, density boxplots. Conditions: Leaves, No Leaves, Twigs, Acacia, Pine. Fire intensities: 50/100/150 kW.
- **Stringybark/** — Data (`stringybark.xlsx`), density boxplots, heatmaps. Species: *E. obliqua* (4 trees, hazard-rated) and *E. radiata*. Hazard ratings: Extreme (0% char), Very High (10–50%), High (50–90%), Moderate (90%).
- **Candlebark/** — Data (`candlebark.xlsx`), density boxplots. Shapes: Flat (1,053 samples) and Cylindrical (1,263). Three fire intensities, three sample lengths (20/40/60 cm).
- **MC and material density/** — Moisture Content and Material Density plots for all three fuel types.
- **Bark density/**, **Bulk density/** — Additional density data.
- **Pearson correlation matrix/** — Correlation analysis outputs.
- **Root scripts**: `density_combined_bark.py` (combined Stringybark + Candlebark density), `safe_standardize_xlsx.py`, `standardize_csv_headers.py`, `verify_formulas.py`.
- **`full result.md`** — Final results document with all statistical tables and figure write-ups. **This is the authoritative results file.**

## Key Statistical Workflow
Each fuel type has an R script (`SA for <type>.R`) that:
1. Fits candidate models (Gamma GLMM via glmmTMB, GAM via mgcv)
2. Selects winner by AIC/RMSE
3. Computes EMMs via `emmeans`
4. Generates per-parameter EMM plots (publication-ready: 5×2.5 dims, no titles, horizontal "Type" y-axis)
5. Writes `model_selection_report.txt` with pairwise comparison summary

**Branchlet** has two variants: with experiment order (random effect) and without.

## Plot Styling Standards (MC & Material Density figures)
- `figsize=(12, 6)` (or proportional), `width=0.5`
- Fonts: `plt.rcParams.update({'font.size': 14, 'axes.labelsize': 16, 'xtick.labelsize': 14, 'ytick.labelsize': 14, 'legend.fontsize': 14, 'axes.titlesize': 16})`
- Density units: `$\mathrm{kg/m^3}$` (upright mathtext, NOT italic)
- `dpi=150`, `notch=True`, `grid(True, linestyle='--', alpha=0.7)`
- Legend: compact, `framealpha=0.9`, `labelspacing=0.2` if needed
- Title Case for all axis labels, titles, legends

## Output Locations
- `Branchlet/R/model_selection_report.txt` — report (with experiment order)
- `Branchlet/R/model_selection_report_no_experiment.txt` — report (without experiment order)
- `Branchlet/R/figures/` — figures (with experiment order)
- `Branchlet/R/figures_no_experiment/` — figures (without experiment order)
- `Stringybark/model_selection_report.txt` — report
- `Stringybark/figures/` — figures
- `Candlebark/R/model_selection_report.txt` — report
- `Candlebark/R/figures/` — figures

## Available Scripts
| Script | Purpose |
|---|---|
| `Branchlet/R/SA for branchlet (with experiment order).R` | Full statistical analysis (with experiment random effect) |
| `Branchlet/R/SA for branchlet (without experiment order).R` | Statistical analysis (no experiment random effect) |
| `Branchlet/R/combined_histogram.R` | 3-panel V/Sa histogram (Leaves, No leaves, Twigs) |
| `Branchlet/density boxplot.py` | Branchlet density boxplot |
| `Stringybark/R/SA for stringybark.R` | Stringybark model selection + EMM figures |
| `Stringybark/density_stringybark_boxplot.py` | Stringybark density boxplot |
| `Stringybark/create_firebrands_heatmap.py` | Firebrand distribution heatmap |
| `Candlebark/R/SA for candlebark.R` | Candlebark model selection + EMM figures |
| `Candlebark/density_candlebark_boxplot.py` | Candlebark density boxplot |
| `density_combined_bark.py` | Combined Stringybark + Candlebark density boxplot |
| `MC and material density/twigs MC.py` | Twig moisture content (reference styling) |
| `MC and material density/twig bulk density.py` | Twig material density |
| `MC and material density/stringybark bulk density.py` | Stringybark MC + density |
| `MC and material density/candle bark bulk density.py` | Candlebark MC + density |
