# Direct intact-ratio T-score prediction (nested ridge)

## Reproduce the exploratory Python result

1. Close and reopen `BoneSORS` from the repository folder.
2. In the Analysis tab, load `Analysis/pairedCadavers.mat` and select `Analysis/CompleteCadaverWorkbook.xlsx` as the category/demographic sheet. These are the inputs used for the validated 38-donor run. Loading different donors, metadata, spectra, or donor order can change the result.
3. Select **Predict T-score**, then **Configure T-score prediction**.
4. Select intact tissue T, expression `3` (6 mm), and exact tag D3P1_MM00 on Analysis. Configure Raman + demographics, all five selected ratios, age/BMI/weight (not sex), normalization none, standardization and block scaling on, and Ridge only. Set alpha grid `[0.01, 0.1, 1, 10, 100]`, five ridge inner folds, and seed `20260919`. Preset buttons were removed on 24 September 2026.
5. Choose an analysis output folder, then **Run selected analysis**.

Expected result with those inputs: r = 0.780591870708, RMSECV = 1.179247932992, and 30/38 correct classifications (78.947%). MATLAB's maximum absolute difference from the 38 saved Python predictions was 3.55e-15.

No reconstruction is run. The five baseline-corrected band-area ratios are PO4/CO3, PO4/Amide III, PO4/CH2, PO4/Amide I, and CO3/Amide III, used together with age, weight in kilograms, and BMI. Sex is not selected. Normalization is explicitly `none`; ratio calculation itself is unchanged.

## Available controls

- Predictor source: **Raman + demographics** allows selected ratios or full spectra. Enable block scaling separately under Preprocessing.
- Model: **Ridge** is also available as an ordinary, non-block-scaled model for Raman-only, demographic-only, or combined predictors.
- Models tab: ridge alpha grid is editable. Validation tab: ridge inner folds and seed are editable. The historical recipe uses `[0.01, 0.1, 1, 10, 100]`, five folds, and seed `20260919`.
- Ratio checkboxes and demographic checkboxes remain editable. Changing them defines a different model, so the reference result is no longer expected.

## Validation and numerical conventions

Outer evaluation leaves out all rows belonging to one cadaver. Inner folds keep cadavers together and select alpha by minimum summed validation squared error. Predictors with missing values are imputed using only the relevant training subset's column medians (zero for a completely missing training column). Means and sample standard deviations are fitted inside each inner and outer training subset.

Block scaling divides the standardized five-ratio block by sqrt(5) and the standardized three-demographic block by sqrt(3). For other representations, the actual block column counts are used. The ridge objective is `sum(residual.^2) + alpha*sum(beta.^2)` with an unpenalized intercept, matching scikit-learn Ridge. The native MATLAB SVD solve does not require Python at runtime. See https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.Ridge.html.

Inner fold assignments match NumPy legacy RandomState shuffle and sklearn KFold, including uneven fold sizes. They use the input donor order and the same integer seed for each outer training set. The helper does not alter MATLAB's global random-number state. Changing input donor order can change the inner splits, just as it does in Python. See https://scikit-learn.org/stable/modules/generated/sklearn.model_selection.KFold.html.

## Saved outputs

Each ordinary Predict T-score ridge run creates a new `tscore_RIDGE_...` subfolder in the selected analysis output directory:

- `predictions.csv`: donor IDs, measured/predicted T-scores, categories, and selected alpha.
- `settings.json`: dataset/workbook paths, feature settings, and validation configuration.
- `result.mat`: predictions, metrics, and per-outer-fold tuning details, including inner donor memberships, fold assignments, and candidate errors.

Prediction and confusion/ROC figures are displayed using the existing GUI plotting functions. No source spectra, category workbook, or prior results are overwritten.

## Scientific scope

The 0.781 result is an exploratory result for the previously retained 38-donor cohort, not independent clinical validation. It is for ratios PLUS demographics, not Raman alone. Nested parameter tuning does not remove bias from choosing a method after examining the same cohort's results.

Implementation checks and full Python/MATLAB donor-level comparisons are saved in `Analysis/Results/ridge_gui_validation_20260919`.
