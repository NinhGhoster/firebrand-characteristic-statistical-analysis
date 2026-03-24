# Agent Context for Chapter 2 Data Analysis

## Project Structure
This repository contains firebrand data analysis for multiple samples under different conditions:
- **Bark density/**
- **Branchlet/** (Contains `branchlet raw data.xlsx` and analysis scripts)
- **Bulk density/**
- **Candlebark/** (Contains `candlebark.xlsx` and density scripts)
- **Stringybark/** (Contains `stringybark.xlsx`, heatmaps, and density scripts)
- **Results_Draft.md** — Draft results section with sample counts, EMM descriptions, and figure write-ups

## Data Analysis & Findings
### Branchlet
- **File**: `Branchlet/branchlet raw data.xlsx`
- **Analysis**: Density boxplots (`Branchlet/density boxplot.py`) comparing Leaves, No Leaves, Twigs, Acacia, and Pine.
- **Key Stats**: Average density ~322 kg/m³.

### Stringybark
- **File**: `Stringybark/stringybark.xlsx`
- **Density Analysis**:
  - Focuses on *E. obliqua* (4 trees by hazard rating) and *E. radiata*.
  - **E. obliqua**: Mean Density ~180 kg/m³.
  - **E. radiata**: Mean Density ~344 kg/m³.
- **Sample Counts**: 1,556 total — 34 *E. radiata* (9 trunk sections), 1,522 *E. obliqua*: Extreme (322, 35 sections), Very High (696, 41 sections), High (203, 27 sections), Moderate (301, 16 sections).
- **Condition Labels**: Hazard ratings — Extreme (0% char), Very High (10–50% char), High (50–90% char), Moderate (90% char). Species comparison uses E. obliqua vs E. radiata.
- **Heatmap Analysis**:
  - Visualizes firebrand distribution across trunk height.
  - Very High (10-50% char T9) has the highest reach (S44).

### Candlebark
- **File**: `Candlebark/candlebark.xlsx`
- **Sample Counts**: 2,316 total — 1,053 flat, 1,263 cylindrical. Fire intensities: 50 kW (671), 100 kW (967), 150 kW (678). Sample lengths: 20 cm (171), 40 cm (356), 60 cm (1,789).
- **Density Analysis**: 
  - Analyzes sheets with "Density (kg/m3)" columns (excludes _AUTO sheets).
  - Primarily "Flat" samples (Cylindrical samples lacked density data).
- **Statistical Models**: Automated model selection (Gamma/GAM, AIC/RMSE) for 7 parameters × 3 datasets (Fire Intensity, Shape, Sample Length). Curve relabelled to "Cylindrical". Publication-ready EMM plots with compact dimensions.
  - **Candlebark**: Mean Density ~263 kg/m³.
- **Note**: Duplicate `*_fire_intensity.png` figures have been removed.

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
            - Generated publication-ready EMM plots: x-axis shows "EMM parameter (units)", y-axis shows "Type" (horizontal label). Condition labels: Leaves, No leaves, Twigs/Eucalyptus (with experiment order) or 50 kW, 100 kW, 150 kW (without experiment order).
            - Added `No Leave vs Twig` dataset.
    - **2026-02-15**:
        - **Stringybark**:
            - Automated model selection (Gamma/Lognormal, AIC/RMSE) for 8 parameters (incl. vol_sa_ratio, sa_vol_ratio) × 2 datasets (Obliqua Char Levels, Species O vs R).
            - Formula: `param ~ height_section + condition + fire_intensity`.
            - Automated count analysis (Poisson vs NB) with overdispersion check.
            - Generated `model_selection_report.txt` with pairwise comparison summary table.
    - **2026-02-26**:
        - **Branchlet**:
            - Revised all EMM figures for publication: removed titles/p-value captions, relabeled axes (EMM + parameter with units, Type), consistent kW spacing.
            - Dynamic column detection for emmeans output (handles `response`/`emmean`/`rate` variants).
            - Condition labels: Leaves, No leaves, Twigs, Eucalyptus, 50 kW, 100 kW, 150 kW.
    - **2026-02-28**:
        - **Stringybark**:
            - Added `vol_sa_ratio` and `sa_vol_ratio` to parameters.
            - Renamed axis label "Height section" → "Trunk section".
            - Per-parameter EMM plots: by condition, fire_intensity, and trunk section (line + ribbon).
            - Removed combined log-scale overlaid figures.
            - Publication-ready: compact 5×2.5 dims, EMM labels with units, Type y-axis, no titles.
        - **Candlebark**:
            - Relabelled shape "Curve" → "Cylindrical".
            - Consistent spacing: 50 kW, 100 kW, 150 kW; 20 cm, 40 cm, 60 cm.
            - Fixed data path (`Candle bark` → `Candlebark`) and `60cm` → `60 cm` filter.
            - Per-parameter EMM plots: by condition and fire_intensity.
            - Removed combined log-scale overlaid figures.
            - Publication-ready: compact 5×2.5 dims, EMM labels with units, Type y-axis, no titles.
    - **2026-03-02 to 2026-03-24**:
        - **Results Draft**:
            - Created `Results_Draft.md` with sample count summary for all three fuel types.
            - Added EMM table and description for Leave vs No Leave, Leave vs Twig comparisons.
            - Added V/SA figure descriptions for Branchlet (fire intensity), Stringybark (Char Levels, Species), and Candlebark (Sample Length, Shape, Fire Intensity).
        - **Branchlet**:
            - Created `combined_histogram.R` — 3-panel V/SA ratio histogram (Leaves, No leaves/Branchlet, Twigs).
        - **Stringybark**:
            - Updated condition labels from char percentages to hazard ratings: Extreme (0% char), Very High (10–50%), High (50–90%), Moderate (90%).
            - Species comparison labels: E. obliqua vs E. radiata (instead of O_0% vs R_0%).
            - Regenerated all Stringybark figures with new labels.
        - **Candlebark**:
            - Removed 21 duplicate `*_fire_intensity.png` figures.

## Environment
- **Conda Environment**: `stas_test` (contains `pandas`, `openpyxl`, `matplotlib`).
- **Workspace Root**: `/Users/firecaster/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Documents/Chapter 2/Chapter 2 data`

## Available Scripts
- `Branchlet/density boxplot.py`: Branchlet density analysis.
- `Branchlet/R/SA for branchlet (with experiment order).R`: Automated branchlet statistical analysis (with experiment order).
- `Branchlet/R/SA for branchlet (without experiment order).R`: Automated branchlet statistical analysis (without experiment order).
- `Branchlet/R/combined_histogram.R`: Combined 3-panel V/SA ratio histogram (Leaves, No leaves/Branchlet, Twigs).
- `Stringybark/density_stringybark_boxplot.py`: Stringybark density analysis.
- `Stringybark/create_firebrands_heatmap.py`: Stringybark heatmap.
- `Stringybark/R/SA for stringybark.R`: Automated Stringybark model selection + per-parameter EMM figures.
- `Candlebark/R/SA for candlebark.R`: Automated Candlebark model selection + per-parameter EMM figures.
- `Candlebark/density_candlebark_boxplot.py`: Candlebark density analysis.
- `density_combined_bark.py`: **MASTER SCRIPT** for combined Bark density (Stringybark + Candlebark).
- `Results_Draft.md`: Draft results section for the paper.

## Output Locations
- `Branchlet/R/model_selection_report.txt` — Branchlet report (with experiment order)
- `Branchlet/R/model_selection_report_no_experiment.txt` — Branchlet report (without experiment order)
- `Branchlet/R/figures/` — Branchlet figures (with experiment order)
- `Branchlet/R/figures_no_experiment/` — Branchlet figures (without experiment order)
- `Stringybark/model_selection_report.txt` — Stringybark report
- `Stringybark/figures/` — Stringybark combined figures
