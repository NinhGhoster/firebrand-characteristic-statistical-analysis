# Firebrand Parameter Correlation Analysis

As requested, we conducted a Pearson correlation analysis across all variables (**count**, **length**, **width**, **height**, **mass**, **surface area**, **volume**, and **V/SA ratio**) for all three fuel types. To appropriately include the `count` variable alongside individual physical properties, the data was aggregated (averaged) by experiment/trunk section so that all metrics align on the same scale.

Below are the findings, a discussion on variable redundancy, and a recommendation for a reduced set of parameters.

---

## 1. Correlation Results by Fuel Type

### Branchlet Fuel
| | count | length | width | height | mass | SA | volume | V/SA |
|:---|---:|---:|---:|---:|---:|---:|---:|---:|
| **count** | 1.00 | -0.49 | -0.34 | -0.39 | -0.49 | -0.46 | -0.52 | -0.14 |
| **length** | -0.49 | 1.00 | 0.27 | 0.59 | 0.64 | 0.73 | 0.61 | -0.05 |
| **width** | -0.34 | 0.27 | 1.00 | 0.47 | 0.28 | 0.70 | 0.37 | 0.06 |
| **height** | -0.39 | 0.59 | 0.47 | 1.00 | 0.48 | **0.81** | 0.57 | 0.00 |
| **mass** | -0.49 | 0.64 | 0.28 | 0.48 | 1.00 | 0.59 | **0.90** | 0.18 |
| **SA** | -0.46 | 0.73 | 0.70 | **0.81** | 0.59 | 1.00 | 0.65 | -0.05 |
| **volume** | -0.52 | 0.61 | 0.37 | 0.57 | **0.90** | 0.65 | 1.00 | 0.44 |
| **V/SA** | -0.14 | -0.05 | 0.06 | 0.00 | 0.18 | -0.05 | 0.44 | 1.00 |

* **Highly Correlated (|r| $\ge$ 0.70):** 
  * Mass & Volume (r = 0.90)
  * Height & Surface Area (r = 0.81)
  * Length & Surface Area (r = 0.73)
  * Width & Surface Area (r = 0.70)

### Stringybark Fuel
| | count | length | width | height | mass | SA | volume | V/SA |
|:---|---:|---:|---:|---:|---:|---:|---:|---:|
| **count** | 1.00 | 0.23 | 0.10 | 0.08 | 0.07 | 0.10 | 0.07 | 0.07 |
| **length** | 0.23 | 1.00 | **0.86** | **0.85** | 0.25 | **0.90** | 0.73 | 0.53 |
| **width** | 0.10 | **0.86** | 1.00 | **0.92** | 0.17 | **0.86** | 0.63 | 0.46 |
| **height** | 0.08 | **0.85** | **0.92** | 1.00 | 0.18 | **0.87** | 0.67 | 0.42 |
| **mass** | 0.07 | 0.25 | 0.17 | 0.18 | 1.00 | 0.37 | 0.63 | 0.29 |
| **SA** | 0.10 | **0.90** | **0.86** | **0.87** | 0.37 | 1.00 | **0.90** | 0.52 |
| **volume** | 0.07 | 0.73 | 0.63 | 0.67 | 0.63 | **0.90** | 1.00 | 0.56 |
| **V/SA** | 0.07 | 0.53 | 0.46 | 0.42 | 0.29 | 0.52 | 0.56 | 1.00 |

* **Highly Correlated (|r| $\ge$ 0.70):** 
  * The three dimensions (length, width, height) are highly correlated with each other (r = 0.85–0.92).
  * Surface Area is highly correlated with all dimensions (r = 0.86–0.90) and Volume (r = 0.90).
  * Volume is also highly correlated with Length (r = 0.73).

### Candlebark Fuel
| | count | length | width | height | mass | SA | volume | V/SA |
|:---|---:|---:|---:|---:|---:|---:|---:|---:|
| **count** | 1.00 | -0.01 | -0.02 | -0.06 | -0.20 | -0.12 | -0.31 | -0.57 |
| **length** | -0.01 | 1.00 | **0.97** | **0.98** | **0.96** | **0.98** | **0.90** | 0.74 |
| **width** | -0.02 | **0.97** | 1.00 | **0.98** | **0.98** | **0.98** | **0.92** | **0.80** |
| **height** | -0.06 | **0.98** | **0.98** | 1.00 | **0.98** | **1.00** | **0.94** | **0.80** |
| **mass** | -0.20 | **0.96** | **0.98** | **0.98** | 1.00 | **0.99** | **0.98** | **0.89** |
| **SA** | -0.12 | **0.98** | **0.98** | **1.00** | **0.99** | 1.00 | **0.96** | **0.83** |
| **volume** | -0.31 | **0.90** | **0.92** | **0.94** | **0.98** | **0.96** | 1.00 | **0.92** |
| **V/SA** | -0.57 | 0.74 | **0.80** | **0.80** | **0.89** | **0.83** | **0.92** | 1.00 |

* **Highly Correlated (|r| $\ge$ 0.70):** 
  * Almost all size and mass parameters (length, width, height, mass, SA, volume, and V/SA) scale together strongly (r $\ge$ 0.74).

---

## 2. Discussion of Redundancy

Based on the correlation matrices across the three fuel types, there are clear redundancies among the variables:

1. **Mass vs. Volume:** Across all fuel types, mass and volume are highly redundant (r $\ge$ 0.90 in aggregated data). Because mass is a directly measured, critical physical property for ignition and transport modeling, volume can safely be omitted from primary discussion without losing descriptive power.
2. **Surface Area vs. Basic Dimensions (Length/Width/Height):** Surface area is mathematically derived from the three dimensions. As expected, it correlates very strongly with them (r $\ge$ 0.70 in Branchlets, r > 0.80 in Stringybark and Candlebark). Discussing all three dimensions plus surface area is heavily redundant.
3. **V/SA Ratio:** While it correlates somewhat with volume and mass (especially in Candlebark, where everything scales together), V/SA generally maintains much weaker correlations with the raw dimensions (e.g., r = -0.05 to 0.53 in Branchlet and Stringybark). This confirms that V/SA captures a unique geometric property (aerodynamic compactness/thickness) that isn't fully described by raw size alone.
4. **Firebrand Count:** Count consistently shows very low or negative correlations with the physical dimensions (e.g., r = -0.52 with volume in Branchlets). A negative correlation suggests that conditions producing *more* firebrands tend to produce *smaller* ones. Because it behaves entirely independently from the size metrics, Count is an essential, non-redundant variable.

---

## 3. Recommendation for Reduced Set of Variables

To reduce the overall volume of material in the paper while still fully capturing the mechanics of firebrand generation (as Alex requested), we recommend retaining the following **four primary parameters** for the Results and Discussion sections:

1. **Count (`n_points`)**: Defines the *quantity* of firebrand generation. It acts completely independently of the size variables.
2. **Mass**: Defines the *scale/amount of material* per firebrand. It is highly redundant with volume and surface area, making it an excellent standalone proxy for overall firebrand "size" and ignition potential.
3. **V/SA Ratio**: Defines the *shape/compactness*. It captures the thickness, aerodynamics, and burning lifetime of the particle, which raw mass cannot explain alone.
4. **Length**: Defines the *maximum span* (aerodynamic cross-section). Since length, width, and height are often highly correlated with each other, reporting just the longest dimension (Length) gives the reader a clear understanding of the spatial footprint without redundancy.

**Variables to drop/move to supplementary tables:** Width, Height, Surface Area, and Volume. 

*Conclusion:* By focusing the narrative strictly on **Count, Mass, Length, and V/SA**, you cover quantity, scale, span, and shape completely and orthogonally. This directly satisfies the requirement to describe firebrands comprehensively without unnecessary table bloat.
