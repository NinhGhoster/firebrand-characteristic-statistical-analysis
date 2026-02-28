# Firebrand characteristic statistical analysis

This repository contains the data, analysis scripts, and statistical findings for Chapter 2: Firebrand Characteristics Data Analysis. It encompasses data regarding various firebrand samples, primarily focusing on physical properties such as dimensions, mass, density, and observed characteristics under different test conditions.

## Project Structure

The project is organized by the type of firebrand material being analyzed:

- **Branchlet/**: Contains raw data (`branchlet raw data.xlsx`) and statistical analysis scripts (`R/`) for Branchlet firebrands. Analyzes properties under different conditions such as Leaves, No Leaves, Twigs, Acacia, and Pine.
- **Stringybark/**: Contains data (`stringybark.xlsx`), density analysis, and heatmap visualization scripts for *Eucalyptus obliqua* and *Eucalyptus radiata* stringybark firebrands.
- **Candle bark/**: Contains data (`candlebark.xlsx`) and density analysis scripts primarily analyzing flat samples of Candlebark.
- **Bark density/** & **Bulk density/**: Directories containing additional density-related data.

## Key Findings & Data Analysis

### Branchlet
- **Density**: Average density evaluated via `density boxplot.py` is approximately 322 kg/m³.
- **Statistical Models**: Automated model selection scripts compare AIC/RMSE across 6 parameters and multiple datasets, including the effects of experiment order. Count data analysis is performed using Poisson and Negative Binomial distributions. Publication-ready EMM plots show parameter-specific x-axis labels with units and a horizontal "Type" y-axis.

### Stringybark
- **Density**: *E. obliqua* (mean ~180 kg/m³) versus *E. radiata* (mean ~344 kg/m³). Analyzed in `density_stringybark_boxplot.py`.
- **Heatmap Analysis**: Visualizes firebrand distribution across trunk height. Findings show *E. obliqua* 10-50% char T9 exhibits the highest reach (S44).
- **Statistical Models**: Automated model selection (Gamma vs. Lognormal) evaluating 8 parameters (incl. vol/SA ratios) against `height_section`, `condition`, and `fire_intensity`. Per-parameter EMM plots by condition, fire intensity, and trunk section.

### Candlebark
- **Density**: Mean density is approximately 263 kg/m³. Evaluated primarily for flat samples in `density_candlebark_boxplot.py`.
- **Statistical Models**: Automated model selection (Gamma/GAM) evaluating 7 parameters across Fire Intensity, Shape (Flat vs Cylindrical), and Sample Length. Per-parameter EMM plots.

### Combined Bark Analysis
- The root script `density_combined_bark.py` combines Stringybark and Candlebark density data into unified visual boxplot comparisons.

## Statistical Methodology

### Model Selection
For each parameter, two candidate models are compared via AIC:
- **Gamma GLMM** (`glmmTMB`, log link) — assumes a linear relationship on the log scale
- **GAM** (`mgcv`) — allows smooth, nonlinear relationships with continuous predictors (e.g., trunk section)

The model with the lower AIC is selected per parameter. This means **different parameters may use different models**, which is standard practice (Burnham & Anderson, 2002). Both models produce comparable estimated marginal means (EMMs) on the response scale, so results are directly comparable across parameters regardless of which model was selected.

Count data (`n_points`) is analyzed separately using Poisson vs. Negative Binomial GLMs, with overdispersion testing to select the appropriate distribution.

### Why V/SA Ratio (Not SA/V)
Both V/SA (volume ÷ surface area) and SA/V (surface area ÷ volume) are mathematical reciprocals containing the same information. However, **V/SA is used** because:

1. **Better statistical properties** — V/SA is bounded in a narrow, well-behaved range (typically 0.2–0.8 for firebrands). SA/V can explode to extreme values for thin particles (e.g., >2000), creating heavy-tailed distributions that violate model assumptions.
2. **Clearer trends** — V/SA shows clear, monotonic trends across trunk sections and conditions with tight confidence intervals. SA/V produces flat, noisy patterns with large CI blowouts due to extreme outlier influence.
3. **Physical interpretability** — V/SA captures firebrand "compactness" or "thickness": higher V/SA = bulkier particle. This relates directly to burning time and transport potential.

## Available Scripts

### R Scripts (Statistical Analysis)
- `Branchlet/R/SA for branchlet (with experiment order).R`
- `Branchlet/R/SA for branchlet (without experiment order).R`
- `Stringybark/R/SA for stringybark.R`
- `Candlebark/R/SA for candlebark.R`

### Python Scripts (Data Processing & Visualization)
- `density_combined_bark.py`: Master script in root for combined Bark density plotting.
- `Branchlet/density boxplot.py`: Branchlet density boxplots.
- `Stringybark/density_stringybark_boxplot.py`: Stringybark density boxplots.
- `Stringybark/create_firebrands_heatmap.py`: Generates firebrand distribution heatmaps.
- `Candlebark/density_candlebark_boxplot.py`: Candlebark density boxplots.
- Various utilities for standardizing dataset headers and formatting (e.g., `standardize_csv_headers.py`, `safe_standardize_xlsx.py`, `verify_formulas.py`).

## Environment Setup

The Python scripts are designed to run in a conda environment (such as `stas_test`) with the following dependencies:
- `pandas`
- `openpyxl`
- `matplotlib`
- `scipy` (for statistics/calculations)

R scripts require standard statistical packages for generalized linear models (GLMs), `MASS` (for Negative Binomial), and `ggplot2` for plotting.

## Outputs
Script outputs, including pairwise comparison summaries (`model_selection_report.txt`) and generated plots (`figures/`), are automatically saved within their respective material directories (e.g., `Branchlet/R/figures/` and `Stringybark/figures/`).