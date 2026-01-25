# Agent Context for Chapter 2 Data Analysis

## Project Structure
This repository contains firebrand data analysis for multiple samples under different conditions:
- **Bark density/**
- **Branchlet/** (Contains `branchlet raw data.xlsx` and analysis scripts)
- **Bulk density/**
- **Candle bark/**
- **Stringybark/**

## Branchlet Data Structure
The file `Branchlet/branchlet raw data.xlsx` contains data on firebrands.
- **Sheets**: Represent different conditions (e.g., 'Pine', 'Acacia', '100 kW', etc.).
- **Columns**: Represent characteristics of the firebrands (e.g., 'Volume (mm3)', 'Surface Area (mm2)', 'Mass (g)').
- **Rows**: Represent individual firebrands, identified by 'File (ID)'.

## History of Changes
- **2026-01-24**: 
    - Initialized Git repository in `Branchlet/` then moved it up to the root project directory `Chapter 2 data/`.
    - **Branchlet Specifics**:
        - Analyzed the structure of `branchlet raw data.xlsx`.
        - Renamed columns 'Volume (mm³)' to 'Volume (mm3)' and 'Surface Area (mm²)' to 'Surface Area (mm2)' across all sheets and 247 associated CSV files.
        - Calibrated `branchlet raw data.xlsx`: Corrected firebrands with Density > 800 kg/m³ using sheet medians and normal distribution randomization. Marked with "cali" column.
        - Finalized `density boxplot.py`: Created a high-quality notched boxplot with specific grouping (Eucalyptus), custom colors, and right-aligned annotations for Mean/Median.

## Environment
- **Conda Environment**: `stas_test` (contains `pandas`, `openpyxl`, `matplotlib`).
- **Workspace Root**: `/Users/firecaster/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Documents/Chapter 2/Chapter 2 data`
