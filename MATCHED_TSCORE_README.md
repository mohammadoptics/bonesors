# Intact 6-mm ratio + demographic comparison: PLS and SVR

## Run in the GUI

1. Reopen `BoneSORS` to refresh its callbacks after this update.
2. Load the original `Analysis/pairedCadavers.mat` and `Analysis/CompleteCadaverWorkbook.xlsx`. Do not load a reconstructed `predictedCadavers.mat` for this direct-intact comparison.
3. Choose an analysis output directory.
4. Select **Predict T-score**, tissue T, expression `3`, and exact tag D3P1_MM00 on Analysis. In **Configure T-score prediction**, explicitly set the predictors, preprocessing, models, and validation values documented below, then **Apply**. Preset buttons were removed on 24 September 2026.
5. Run the analysis. Both models are selected; uncheck either model on the Models tab to run only the other.

The historical recipe uses measured intact tissue T, spectrum 3 (6 mm), exact tag D3P1_MM00, all five regional-area ratios, age/weight/BMI, and no sex predictor. Choose Raman + demographics, selected ratios, normalization none, column standardization and block scaling on, and PLS + SVR. No reconstruction or spectral subtraction is used. The expected reference cohort has 38 donors; different data, donor ordering, demographics, or settings can change the result.

| Model | Reference r | Reference RMSECV | Correct categories |
|---|---:|---:|---:|
| PLS | 0.795463175771 | 1.145645135738 | 29/38 |
| RBF-SVR | 0.796704704803 | 1.143240423287 | 28/38 |

## Validation and scaling

Outer validation leaves out a whole cadaver. Inner validation uses five shuffled donor folds on the remaining cadavers, with seed 20260919, original donor order, and NumPy-compatible fold sizes. The seed is reused for each outer training cohort. PLS evaluates components 1 through 8; SVR evaluates all 126 combinations of:

- C: 0.1, 0.3, 1, 3, 10, 30, 100.
- Epsilon: 0.01, 0.1, 0.3.
- Kernel sigma: 0.3, 0.7, 1.5, 3, 10, 30.

The candidate with minimum pooled inner validation squared error is refitted on the outer training donors. There is no selection by the outer correlation. Missing predictor values use training medians, columns use training means/sample standard deviations, and the standardized ratio and demographic blocks are divided by sqrt(5) and sqrt(3), respectively. No second standardization undoes these block weights. All these operations are repeated within each inner training fold.

The **Matched K-fold (complete grid)** protocol is explicit on the Validation tab. Original PLS inner-LOCO and native MATLAB SVR modes remain unchanged. In matched mode, the matched fold count is used, the full SVR grid is evaluated, and the random-grid candidate budget is disabled. Enter the C/epsilon/sigma grids in the grid fields, not the fixed-parameter edit boxes.

## Solver implementation

PLS is native MATLAB `plsregress` after the explicit training-only transformations. It reproduces the Python PLS reference on these data to floating-point precision.

Matched SVR deliberately uses **scikit-learn from the MATLAB GUI**, not `fitrsvm`, to preserve the original solver's tolerance, kernel, and numerical behavior. MATLAB extracts the predictors and handles the plots/output; a dedicated Python helper fits all inner and outer models afresh. It receives only the current feature matrix, outcomes, donor grouping, and settings in a temporary local MAT file. It does not read any saved predictions or send data over the network. Temporary exchange files are removed on completion/failure.

SVR uses `gamma = 1/(2*sigma^2)`, epsilon-insensitive loss, tolerance 0.001, and shrinking enabled. MATLAB's Gaussian kernel-scale convention differs; copying the same numeric scale into the legacy `fitrsvm` mode does not reproduce this setup. Documentation: [scikit-learn SVR](https://scikit-learn.org/stable/modules/generated/sklearn.svm.SVR.html), [MATLAB fitrsvm](https://www.mathworks.com/help/stats/fitrsvm.html).

The **SVR Python** executable field on the Validation tab is configurable. Use a Python 3.12 environment, install `app/analysis/requirements_matched_svr.txt`, and set that executable path. No Python environment is needed for PLS or the original native MATLAB SVR mode.

## Saved results

Each model writes a separate timestamped `tscore_PLS_*` or `tscore_SVR_*` folder inside the chosen analysis output directory:

- `predictions.csv`: measured/predicted T-score, categories, and each outer fold's chosen components or SVR parameters.
- `result.mat`: predictions, metrics, all candidate inner errors, fold assignments, and configuration. Matched SVR also records runtime package versions.
- `settings.json`: source paths, feature selections, scaling, grids, seed, and validation protocol.

Plots are displayed using the existing prediction and classification figure functions. The saved results do not overwrite previous runs.

## Interpretation

These results reproduce an exploratory comparison on the historically retained cohort. Reproducing a score does not remove earlier cohort-selection or model-comparison bias, and these models still require independent validation. Do not present the higher correlation as proof of superiority to ridge; the verified ridge comparator had 30/38 correct categories.
