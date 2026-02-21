# Agent Context for Chapter 2 Data Analysis

## Project Structure
This repository contains firebrand data analysis for multiple samples under different conditions:
- **Bark density/**
- **Branchlet/** (Contains `branchlet raw data.xlsx` and analysis scripts)
- **Bulk density/**
- **Candle bark/** (Contains `candlebark.xlsx` and density scripts)
- **Stringybark/** (Contains `stringybark.xlsx`, heatmaps, and density scripts)

## Data Analysis & Findings
### Branchlet
- **File**: `Branchlet/branchlet raw data.xlsx`
- **Analysis**: Density boxplots (`Branchlet/density boxplot.py`) comparing Leaves, No Leaves, Twigs, Acacia, and Pine.
- **Key Stats**: Average density ~322 kg/m³.

### Stringybark
- **File**: `Stringybark/stringybark.xlsx`
- **Density Analysis**:
  - Focuses on "E  obliqua 0% char T5" and "E  radiata 0% char T8".
  - **E. obliqua**: Mean Density ~180 kg/m³.
  - **E. radiata**: Mean Density ~344 kg/m³.
- **Heatmap Analysis**:
  - Visualizes firebrand distribution across trunk height.
  - E. obliqua 10-50% char T9 has the highest reach (S44).

### Candlebark
- **File**: `Candle bark/candlebark.xlsx`
- **Density Analysis**: 
  - Analyzes sheets with "Density (kg/m3)" columns (excludes _AUTO sheets).
  - Primarily "Flat" samples (Curve samples lacked density data).
  - **Candlebark**: Mean Density ~263 kg/m³.

### Combined Bark Analysis
- **Script**: `density_combined_bark.py` (Root directory)
- **Purpose**: Combines Stringybark and Candlebark density data into a single comparison plot.
- **Categories**:
  - Stringybark E. obliqua
  - Stringybark E. radiata
  - Stringybark Total
  - Candlebark
  - Grand Total
- **Style**: All white notched boxplots, Mean (Red Diamond) & Median (Black Line) stats annotated right of the boxes.

## History of Changes
- **2026-01-24**: 
    - Initialized Git repository and moved to `Chapter 2 data/`.
    - **Branchlet**: Cleaned column names, calibrated density > 800, finalized boxplot.
- **2026-01-25**:
    - **Stringybark**: Created density boxplot, added "Total", removed colors.
    - **General**: Standardized headers in 800+ CSVs and 5 Excels.
- **2026-01-26**:
    - **Candlebark**: 
        - Created `density_candlebark_boxplot.py`.
        - Found no density data for "Curve", so plot shows "Candlebark" (derived from Flat) only.
        - Refined plot: "Species" -> "Candlebark", removed tick labels, adaptive width.
    - **Combined Analysis**:
        - Created `density_combined_bark.py` in root.
        - merged Stringybark and Candlebark data.
        - Finalized style: White boxes, Legend with Frame, X-axis "Bark".

    - **2026-02-14**:
        - **Branchlet**:
            - Automated model selection (AIC/RMSE) for 6 parameters across 6 datasets.
            - Automated count data analysis (Poisson vs NB) with overdispersion check.
            - Generated `model_selection_report.txt` with pairwise comparison summary table.
            - Generated plots with parameter titles and pairwise p-values.
            - Added `No Leave vs Twig` dataset.
    - **2026-02-15**:
        - **Stringybark**:
            - Automated model selection (Gamma/Lognormal, AIC/RMSE) for 6 parameters × 2 datasets (Obliqua Char Levels, Species O vs R).
            - Formula: `param ~ height_section + condition + fire_intensity`.
            - Automated count analysis (Poisson vs NB) with overdispersion check.
            - Generated `model_selection_report.txt` with pairwise comparison summary table.
            - Combined figures: single overlaid graph per factor (height, fire intensity, condition) with log y-axis and color-coded parameters.

## Environment
- **Conda Environment**: `stas_test` (contains `pandas`, `openpyxl`, `matplotlib`).
- **Workspace Root**: `/Users/firecaster/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Documents/Chapter 2/Chapter 2 data`

## Available Scripts
- `Branchlet/density boxplot.py`: Branchlet density analysis.
- `Branchlet/R/SA for branchlet (with experiment order).R`: Automated branchlet statistical analysis (with experiment order).
- `Branchlet/R/SA for branchlet (without experiment order).R`: Automated branchlet statistical analysis (without experiment order).
- `Stringybark/density_stringybark_boxplot.py`: Stringybark density analysis.
- `Stringybark/create_firebrands_heatmap.py`: Stringybark heatmap.
- `Stringybark/statistical analysis for stringybark.R`: Automated Stringybark model selection + combined figures.
- `Candle bark/density_candlebark_boxplot.py`: Candlebark density analysis.
- `density_combined_bark.py`: **MASTER SCRIPT** for combined Bark density (Stringybark + Candlebark).

## Output Locations
- `Branchlet/R/model_selection_report.txt` — Branchlet report (with experiment order)
- `Branchlet/R/model_selection_report_no_experiment.txt` — Branchlet report (without experiment order)
- `Branchlet/R/figures/` — Branchlet figures (with experiment order)
- `Branchlet/R/figures_no_experiment/` — Branchlet figures (without experiment order)
- `Stringybark/model_selection_report.txt` — Stringybark report
- `Stringybark/figures/` — Stringybark combined figures
