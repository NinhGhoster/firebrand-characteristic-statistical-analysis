# Agent Context for Branchlet Data Analysis

## Data Structure
The file `branchlet raw data.xlsx` contains data on firebrands.
- **Sheets**: Represent different conditions (e.g., 'Pine', 'Acacia', '100 kW', etc.).
- **Columns**: Represent characteristics of the firebrands (e.g., 'Volume (mm3)', 'Surface Area (mm2)', 'Mass (g)').
- **Rows**: Represent individual firebrands, identified by 'File (ID)'.

## History of Changes
- **2026-01-24**: 
    - Analyzed the structure of `branchlet raw data.xlsx`.
    - Renamed columns 'Volume (mm³)' to 'Volume (mm3)' and 'Surface Area (mm²)' to 'Surface Area (mm2)' across all sheets to ensure compatibility and consistency.
    - Verified the change by inspecting multiple sheets (Pine, Acacia, candle bark density).
    - Initialized Git repository and successfully tracked all files including `AGENTS.md`, `branchlet raw data.xlsx`, CSV files, and all data subdirectories (`Pine`, `Acacia`, `Twigs` etc.).
    - Renamed columns 'Volume (mm³)' to 'Volume (mm3)' and 'Surface Area (mm²)' to 'Surface Area (mm2)' in all 247 CSV files recursively to match Excel structure.
    - Calibrated `branchlet raw data.xlsx`:
        - Identified firebrands with Density > 800 kg/m³.
        - Recalculated their Mass using [Volume * Median_Sheet_Density].
        - Replaced their Density with randomized values centered around the Median_Sheet_Density (using normal distribution and standard deviation of valid data) to create natural variation.
        - Marked these rows with "cali" in a new `Calibration` column.
    - Updated `density boxplot.py` to:
        - Plot densities from the calibrated Excel file.
        - Group "Leave", "No Leave - Branchlet", and "Twigs (2)" as "Eucalyptus" (same color).
        - Plot "Acacia" and "Pine" distinctly.
        - Added "Total" category combining all data.
        - Disabled outlier filtering to show all points (including calibrated ones).
        - Remove titles and standardise formatting.




## Environment
- **Python Environment**: Uses Conda environment `stas_test` which has `pandas` and `openpyxl` installed.
- **Location**: `/Users/firecaster/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Documents/Chapter 2/Chapter 2 data/Branchlet`
