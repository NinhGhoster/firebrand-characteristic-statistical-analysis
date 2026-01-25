# Stringybark Firebrands Analysis Project

## Project Overview
Analysis of bark firebrand distribution along tree height for 5 stringybark trees (Eucalyptus species) with different char levels. The project visualizes the number of firebrands at different sections (heights) from S1 (bottom) to S44 (top).

## Data Source
**File**: `stringybark.xlsx`
**Location**: `/Users/firecaster/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Documents/Chapter 2/Chapter 2 data/Stringybark/`

## Data Structure
- **5 Sheets** (one per tree):
  1. E radiata 0% char T8 (34 firebrands, max section: S25)
  2. E obliqua 0% char T5 (322 firebrands, max section: S36)
  3. E obliqua 10-50% char T9 (696 firebrands, max section: S44)
  4. E obliqua 50-90% char T16 (203 firebrands, max section: S33)
  5. E obliqua 90% char T17 (301 firebrands, max section: S20)

- **Key Columns**:
  - Column B: File ID (format: "S5a_mesh_4.ply", where S5 = section 5)
  - Column C: Volume (mm³)

## Data Processing
1. Extract section number from File ID (e.g., "S5a_mesh_4.ply" → S5)
2. Count number of records (firebrands) per section
3. Aggregate by section across all files with same section prefix

## Completed Work

### Scripts Created
1. **analyze_data.py** - Initial data exploration and analysis
2. **create_firebrands_heatmap.py** - Main heatmap visualization script (CURRENT)

### Output
- **firebrands_heatmap.png** - Final heatmap showing number of firebrands by tree and section height
  - X-axis: Tree species & char level (ordered: T8, T5, T9, T16, T17)
  - Y-axis: Trunk section height (S1=bottom, S44=top)
  - Color intensity: Number of firebrands (yellow=0, dark red=high)
  - Blank areas: Sections beyond each tree's maximum height

## How to Run

### Prerequisites
```bash
conda activate stas_test
```

### Generate Heatmap
```bash
cd "/Users/firecaster/OneDrive - The University of Melbourne/Documents/Chapter 2/Chapter 2 data/Stringybark"
python create_firebrands_heatmap.py
```

## Key Findings
- **E obliqua 10-50% char T9** reaches highest (S44) with 696 total firebrands
- **E obliqua 90% char T17** shortest (S20) with 301 total firebrands
- **E radiata 0% char T8** has fewest firebrands (34 total) at S25 max
- Firebrands concentrated in mid-height sections across all trees

## Heatmap Details
- No title (removed for publication)
- Tree order: T8, T5, T9, T16, T17 (left to right)
- Section labels: S1 (bottom) to S44 (top)
- Masked blank cells show where trees don't have data
- Annotations display exact firebrand count in each cell
- Color scale: YlOrRd (Yellow-Orange-Red)

## Future Enhancements
- Add statistical analysis (mean, std dev per tree)
- Compare distribution patterns between char levels
- Export aggregated data to CSV for further analysis
- Create additional visualizations (box plots, distribution curves)

## File Locations
- **Working Directory**: `/Users/firecaster/OneDrive - The University of Melbourne/Documents/Chapter 2/Chapter 2 data/Stringybark/`
- **Data File**: `stringybark.xlsx`
- **Scripts**: 
  - `analyze_data.py`
  - `create_firebrands_heatmap.py`
- **Output**: `firebrands_heatmap.png`

## Important Notes
- Section heights NOT consistent across trees (hence blank areas in heatmap)
- Each row is a "firebrand" or individual measurement record
- Sections are 1-indexed (S1 is first section from ground)
- S42 and S43 don't exist in data (no trees sampled at those heights)
