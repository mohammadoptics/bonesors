# BoneSORS GUI guide

Run `BoneSORS` from MATLAB to open the application.

## Two-stage workflow

### Tab 1: Individual Cadavers

1. Load one or more processed individual-cadaver MAT files.
2. Inspect raw or normalized fields and spectrum columns.
3. Choose whether to create an exposed-only, paired exposed/intact, or intact-only
   cadaver dataset and click **Create MAT dataset**. Alternatively, create a
   spectra-table dataset with **Build spectra table**.

This tab intentionally contains no cohort-level ratios, prediction, or machine-learning
analysis.

### Pair and Save (Create MAT dataset)

In **Individual Cadavers**, load the processed specimen MAT files for your
cohort and select **Exposed only**, **Paired exposed/intact**, or **Intact only**.
**Create MAT dataset** uses all loaded files. In paired mode, cadaver spectra
must have both E and T measurements with the same specimen ID and acquisition
tag. Intact-only records with IDs beginning with `IV` are also retained in
paired mode.

To change the filters, open [`app/pairAndSave.m`](app/pairAndSave.m) in the
MATLAB Editor and edit the settings near the top. Save the file before clicking
**Create MAT dataset**.

#### Keep selected acquisition tags

Set `allowTags` to the full base tags you want to keep across the cohort:

```matlab
allowTags = {'D2P1_MM00', 'D3P1_MM00'};
```

Copy the tag spelling and capitalization from the acquisition names. Omit the
specimen ID, tissue marker, file extension, and any trailing repeat suffix
such as `_r02`. The filter matches the base tag exactly, so
`D2P1_MM00` also keeps repeats such as `D2P1_MM00_r02`. Set
`allowTags = {};` to keep all tags eligible for the selected save mode.

#### Exclude specimens or individual spectra

For a manual exclusion list, set `filterSpectraSource = "manual";` and replace
`manualFilterSpectra` with your study's entries. These IDs are fictitious:

```matlab
filterSpectraSource = "manual";
manualFilterSpectra = {
    'XX000001_T', {'D2P1'}
    'XX000002',   {'D3P1_MM00'}
    'XX000003',   {}
};
```

- `XX000001_T` excludes intact spectra whose tags start with `D2P1`.
  Append `_T` for intact tissue or `_E` for exposed bone. A bare ID applies
  to both tissues.
- `XX000002` excludes the exact tag `D3P1_MM00` for both tissues. An
  exclusion tag containing an underscore is matched exactly, so list
  `D3P1_MM00_r02` explicitly if you also need to exclude that repeat.
- `XX000003` excludes all spectra for that specimen. With an empty tag list
  and a tissue suffix, all spectra for that tissue are excluded.

To use an Excel list, set `filterSpectraSource = "askFile";` and answer **Yes**
when prompted. Enter the specimen ID in column A and one exclusion tag per
cell in columns B onward. Leave those cells blank to exclude all spectra for
that ID. Put all tags for a given ID or tissue-specific ID on one row. Set
`filterSpectraSource = "none";` to turn off specimen-specific exclusions.

In paired mode, excluding either side of a cadaver pair also removes its
counterpart from the saved pair. A specimen with no surviving spectra can
appear as an empty record when `allowTags` is empty. Check the specimen
and spectrum counts before analysis.

Choose an output location when prompted. The GUI saves the dataset as
`cads` in the MAT file and writes `pairAndSave_settings.tex` beside it by
default. Use a separate output folder per run to keep each settings report
with its dataset.

### Tab 2: Dataset Analysis

1. Load one generated MAT dataset. This state is separate from the individual files in
   Tab 1.
2. Load a category sheet when required.
3. For analyses that save MAT/CSV results, click **Choose analysis output folder**.
4. Select the analysis and its applicable primary tissue, comparison tissue, spectrum,
   and tag options.
5. Run the workflow with the single **Run selected analysis** button.

The loader identifies three dataset types: a cadaver dataset (`cads`, `cadavers`, or
`pairedCadavers`), a spectra table (`tbl`), or saved LOCO results (`TblPred`). The
dispatcher prevents an analysis from running on the wrong dataset type.

All single-tissue analyses can use exposed (E), predicted (P), or
intact/transcutaneous (T) spectra. Comparison analyses expose both **Primary
tissue** and **Compare with** controls, so the user may select any deliberate E/P/T
pair.

## Spectrum expressions

The **Spectrum expression** field accepts ordered column expressions:

- `2` uses column 2.
- `3-2` normalizes columns 3 and 2 independently, then calculates normalized
  column 3 minus normalized column 2.
- `3+2` normalizes each selected column independently, then adds them. More than
  two columns can be added, for example `3+2+1`.
- `3|2` normalizes each selected column independently, then concatenates the
  feature blocks in the written order. Comma- or space-separated lists such as
  `3,2` are canonicalized to `3|2`.

Addition and subtraction produce one physical-spectrum-shaped result and are
available to spectrum and ratio analyses. Concatenation produces a multi-block
feature vector, so it is available to T-score and feature-vector analyses rather
than plots that require one wavenumber axis.

Select **Reconstruct spectra** and choose PLS, MLP, or kernel ridge in
**Configure reconstruction**. Outputs go to the analysis output folder.

## T-score validation

PLS T-score prediction uses strict nested grouped leave-one-cadaver-out
validation. For every outer held-out cadaver, the PLS rank is selected by an
inner grouped LOCO loop using only the outer training cadavers. Predictor
standardization is also fitted within the applicable training fold. The reported
plot therefore shows the range and median of fold-specific ranks rather than a
rank selected from the outer evaluation predictions.

## Spatial plots

Two additional analyses use the tags selected in the Analysis tab:

- **Spatial spectra by diagnosis** creates one figure with separate N, OPE, and OP
  panels. Within each panel, the category-average spectra for the selected tags are
  vertically stacked.
- **Spatial ratios and FWHM profiles** creates one three-panel Raman-ratio figure and
  one separate three-panel FWHM-derived figure. The ratio panels are PO4/CO3,
  PO4/Amide III, and PO4/CH2. The second figure contains FWHM CH2, FWHM Amide I,
  and reciprocal carbonate width (1/FWHM CO3). Each panel shows N, OPE, and OP category
  means with SEM error bars across the selected tags.

For these modes, the GUI automatically uses **All selected**. The order of the tags
in **Selected / priority order** determines the spectrum stack order and the
left-to-right spatial axis. Use **Move up** and **Move down** to arrange locations
such as MP20, MP15, MP10, MP05, MM00, MD05, MD10, and MD15.

## Tag policies

- **Single exact tag** requires exactly one selected tag, such as `D2P1_MM00`.
- **Priority fallback** tries the selected tags from top to bottom and uses the first
  tag available for each cadaver. The Move up/down buttons define priority.
- **All selected** creates one record for each matching cadaver-tag combination. It is
  intended for exploratory plots. Predictive modes reject this policy so the same
  cadaver cannot enter a validation analysis more than once.

Exact matching is the safe default. Prefix matching supports deliberate groups such as
`D2P1`, but it must be selected explicitly.

## Main modules

- `BoneSORS.m`: layout and thin user-action callbacks.
- `loadAnalysisDataset.m`: separate generated-dataset loader and type detection.
- `runSelectedAnalysis.m`: the only analysis-button dispatcher.
- `runReconstructionAnalysis.m`: common entry point for PLS, MLP, and kernel-ridge
  reconstruction.
- `refreshAnalysisTags.m`: tag discovery from the loaded generated dataset.
- `guiDefaultConfig.m`: central user-facing defaults.
- `analysisModeRegistry.m`: analysis names shown by the GUI and their internal IDs.
- `getGuiAnalysisOptions.m`: validated configuration access.
- `normalizeTagSelection.m`, `extractAcquisitionTag.m`, and `selectTagRows.m`:
  shared tag parsing and selection.
- `parseSpectrumExpression.m`: ordered spectrum-operation parsing shared by every
  dataset analysis.
- `refreshAvailableTags.m`: discovers tags when files are loaded.
- `validateAnalysisRequest.m`: prevents unsafe analysis combinations.
- `runCadaverDatasetAnalysis.m`: the small cadaver-analysis dispatcher with no
  scientific calculations.
- `analyzePairedCadavers.m`: a compatibility wrapper retained for older scripts;
  the GUI no longer calls it.
- `app/analysis/analysis<Name>.m`: one entry module for each selectable cadaver-dataset
  analysis.
- `app/analysis/buildAnalysisContext.m`, `app/analysis/collectRecords.m`, and
  `app/analysis/analysisDefaultSettings.m`: shared validated inputs and scientific
  defaults.
- Other files under `app/analysis/`: focused calculation, plotting, and validation
  helpers extracted from the former monolithic analysis function.

The obsolete `splitSpectraFlag` and its category-row-dependent spectrum switching have
been removed. Spectrum columns are now explicit.

## Strict end-to-end T-score prediction (BOE reference run)

Strict validation now has its own **Configure strict validation...** button.
Ordinary T-score configuration and ratio-display normalization do not change
its E/P models. No presets or settings-loading controls are added.

To reproduce `Results/Final_peak_norm_BOE_PublishedPaper`, load the original
`pairedCadavers.mat` and category workbook. Select **Strict end-to-end T-score
prediction**, one exact analysis location **D3P1_MM00**, and spectrum expression
**2** (3 mm). Select a new output folder and inspect the strict configuration:

- Reconstruction: D2P1_MM00 and D3P1_MM00 training rows; intact columns 2,3;
  second-minus-first difference (6 minus 3 mm); CH2 peak normalization per
  column; exposed target 2; five fixed NIPALS components; X/Y standardization.
- Measured E: column 2, CH2 peak, predictor standardization, fixed SVR
  C=12.5, epsilon=0.3, width=112.5.
- Reconstructed P: main Analysis expression 2, CH2 peak, predictor
  standardization, fixed SVR C=0.75, epsilon=0.01, width=30.
- Numerics: NIPALS max iterations 1000 and tolerance 1e-6; population scaling
  (ddof=0); Python RBF-width convention; native MATLAB SMO tolerance 1e-6.

MATLAB's Gaussian width is internally multiplied by sqrt(2) when the Python
convention is selected, so the specified kernel is exp(-distance^2/(2*width^2)).
Reconstruction and SVR execute natively in MATLAB; Python is not needed to run
the GUI. SIMPLS, sample scaling, and MATLAB-width convention remain explicit
options for older MATLAB comparisons.

Both the outer donor and each training-feature target donor are excluded from
the applicable reconstruction fit. Independent per-spectrum normalization is
cached, but learned scaling and fitting are repeated using only training rows.
The exported P dataset contains donor-LOCO spectra for ratio/average plots;
ordinary LOCO on that saved dataset is not interchangeable with this strict
end-to-end T-score procedure.

On the 38-donor reference, native MATLAB reproduces the saved CSV summary at
three decimals: E r=0.882, RMSECV=0.900; P r=0.689, RMSECV=1.395. All predicted
WHO classes match. Donor-level differences are under 0.0008 T-score units
because native MATLAB SMO and sklearn LIBSVM have different stopping rules;
the two implementations are not claimed to be bit-for-bit identical.

## Normalization for Raman ratio and FWHM display

For **Display Raman ratios**, **Display Raman FWHM**, **Compare ratio plots**, and **Category-average spectra**, choose the reference
region and normalization method below the analysis options. These controls are
independent of the T-score configuration. Available regions are PO4, CO3, CH2,
Amide I, Amide III, and Full spectrum; methods are peak height,
baseline-corrected peak, and area. The default remains PO4 / peak.
**None** skips normalization and disables the method selector. Expressions
such as `3-2` then operate directly on the loaded intensities. This does not
undo any normalization already applied before saving the input dataset.
This option is allowed for these display modes without changing the T-score
requirement to normalize before combining multiple spectra.
**Display Raman FWHM** produces a standalone five-panel figure for PO4, CO3,
Amide III, CH2, and Amide I, using the same selected tissue, tags, expression,
category colors/markers, mean +/- SD bars, and pairwise significance stars as
the ratio display. Widths are in cm^-1, measured above the local minimum within
the existing band windows using interpolated half-height crossings. Undefined
widths are omitted separately for each band; an entirely invalid band shows
"No valid measurements". Difference-spectrum widths describe the difference
spectrum, not the intrinsic widths of the original tissue bands. Concatenated
features and ratio-level combinations are not physical spectra for this display.

The selection is shared across these display modes, making it easy to compare
ratio plots and average spectra with the same normalization. In category-average
mode, normalization is applied to each original column before the expression
is evaluated per cadaver and the resulting spectra are averaged by category.
The existing optional spectral smoothing is unchanged; no final normalization
is applied to the category mean by default. Plot titles identify the region
and method used.

For `3-2`, each selected column is normalized separately, then normalized
column 2 is subtracted from normalized column 3, then the existing
baseline-corrected band-area ratios are calculated. `3+2` follows the same
normalization-first order before addition. There is no second normalization
of the combined spectrum. Concatenation is a T-score feature representation,
not one physical spectrum for ratio display, so it is rejected here.

For one spectrum, scalar normalization cancels from its band-area ratios.
For subtraction, cancellation of denominator bands can make ratios unstable
or undefined; these derived ratios are not ordinary bone composition ratios.

## Configurable spectral reconstruction

Select **Reconstruct spectra**, then open **Configure reconstruction...**.
Choose PLS, MLP, or RBF kernel ridge on its **Model and validation** tab.
Only controls for the selected model are enabled. This dialog, rather than the disabled
main tissue/spectrum/tag controls, determines reconstruction settings:

- Ordered intact column selection; concatenation, mean, addition, difference,
  or mean plus difference. In this legacy reconstruction engine, `diff` is
  **second selected minus first selected**: columns `2,3` mean 6-mm minus 3-mm.
- One or more exposed target columns reconstructed jointly (1=0, 2=3, 3=6 mm).
- Exact training/prediction tags and included categories; blank means all.
- Separate intact and exposed normalization region/method. Choose `none` to
  skip normalization on either side; there are no additional enable switches.
  The method control is disabled for `none`. Otherwise every column is normalized separately.
- Fixed PLS component count or automatic inner cadaver-wise LOCO selection,
  with scaling learned within each inner fold. Outer validation is always LOCO.
  PLS autoscaling is optional; MLP and KRR always standardize within training folds.
- The **PLS algorithm** tab selects NIPALS (Python-compatible, now the default)
  or SIMPLS (previous MATLAB method). NIPALS uses regression deflation, with
  maximum iterations 5000 and squared weight-change tolerance 1e-6 by default.
  The same algorithm is used in inner rank selection and the final outer fit.
  Old configurations without an algorithm field receive the new NIPALS default;
  explicitly choose SIMPLS when reproducing an older MATLAB reconstruction.
- MLP architecture, training algorithm, epochs, regularization and random seed;
  KRR alpha and gamma multiplier. Only the selected model's settings are used.
  MLP requires `fitnet`; no alternative algorithm is silently substituted.
- Combined MAT, individual MAT, or both output formats; filenames and save verification.

Choose **Analysis output folder**, then run. By default each run creates a new
`reconstruction_<model>_<timestamp>_<suffix>` folder inside it. Disabling this
option saves directly there, but existing output files cause an error instead
of being overwritten. The run saves configuration/provenance/status in
`reconstruction_settings.json`, a metrics CSV, and the selected MAT outputs.
`predictedCadavers.mat` contains `cads`: measured E and intact T are preserved,
predictions are stored in P at the physical target columns (unpredicted lower
columns contain NaN), and donor metadata are retained. `reconstructionInfo`
records each donor's training IDs, effective component count, and PLS algorithm,
tolerance, iteration limit, and per-component iteration counts.

The default GUI setting reconstructs all three offsets with CH2 peak
normalization, intact columns 2,3 / difference, and fixed PLS 8. The native MATLAB
NIPALS implementation was verified against sklearn 1.7.2 on all 73 paired rows
from the 38 R04191 cadavers (maximum absolute spectral difference <1e-14).
SIMPLS and NIPALS can give different predictions for multi-output regression;
matching the component count alone does not make the fits equivalent.
The displayed reconstruction correlation is
spectral agreement, not T-score prediction correlation. For strict end-to-end
T-score validation, reconstruction must still be repeated within T-score folds;
ordinary GUI T-score analysis of a saved P dataset does not do that.

## Configuring T-score comparisons

Select tissue, offset expression, and all anatomical locations on the main
Analysis page. For an individual prediction, choose single/priority tag,
concatenated locations, or mean location features using the dropdown beneath
the tag lists. There is no second location editor inside the T-score dialog.

The T-score dialog separates five decisions:

1. **Predictors:** Raman only, demographics only, or Raman + demographics;
   choose full spectra or ratio features and the individual demographic variables.
2. **Preprocessing:** spectral normalization, training-fold column standardization,
   and an independent **Enable block scaling** checkbox. Block scaling is available
   for combined Raman/demographic inputs with PLS, SVR, Ridge, and MLP. It requires
   column standardization and divides each standardized block by the square root
   of its actual column count. CNN remains restricted to full Raman spectra only.
3. **Models:** select multiple models for comparison and edit their settings on
   separate model tabs. SVR parameter grids/search bounds and ridge alpha grids
   are editable. Selecting block scaling does not select a model or feature mode.
4. **Validation:** outer validation stays grouped LOCO. The original PLS/SVR recipe
   retains PLS inner LOCO and MATLAB SVR tuning. The matched recipe uses grouped
   inner K-fold PLS and complete-grid scikit-learn SVR through the displayed Python
   executable. Select complete-grid nested tuning for matched SVR. Ridge retains
   its separate inner-fold setting; MLP/CNN use their fixed training settings.

5. **Figure:** choose individual output or multi-panel comparison. The checklist
   lists the selected Analysis locations and, when there are multiple locations,
   their concatenation. Independently check Raman only and Raman + demographics
   for each row, and optionally include a demographics-only panel at the top.
   Demographic panels are disabled when no demographic variables are selected.
   Confirmed unavailable fields in the loaded category metadata are also disabled.

All preset/load-settings buttons have been removed. Figure selection never
replaces models, parameter grids, normalization, validation protocol, or seed.
Apply saves explicit selections; Cancel retains the previous configuration.
SVR bandwidths must still be appropriate for the chosen preprocessing: the same
numeric kernel scales need not suit both unblocked Raman and block-scaled inputs.

Multi-panel output fits only checked panels on the same complete donor cohort.
Only locations and demographics used by those panels determine eligibility.
Letters, rows, caption, classification counts, and exports adapt to the selected
panels. Paired comparisons share a row; unpaired panels are centered. Numeric
results and per-panel effective settings are saved with the figure. Select an
analysis output directory to save PNG, PDF, FIG, predictions, metrics, and caption.

The live summary shows the effective configuration; incompatible combinations
show an inline explanation and disable Apply. Spectral normalization and predictor
standardization are different steps: choosing `none` for the former does not turn
off the latter. Per-spectrum ratio concatenation/ratio-level difference features
do not use spectral normalization. Mean/difference ratio representations require
exactly two selected spectra. "Ratios concatenated across spectra" is the corrected
label for the old, misleading "Spectrum + selected ratios" option; its calculation
has not changed.

Models share outer test cadavers only when their eligible input rows match.
Original models remove nonfinite predictor rows; ridge and matched PLS/SVR impute
within training folds. This distinction is unchanged. All comparisons remain
exploratory if their settings were chosen after inspecting this cohort's results.

## Adding an analysis module

1. Add its display label and internal value to `analysisModeRegistry.m`.
2. Create one `app/analysis/analysis<Name>.m` entry module.
3. Put scientific defaults in `app/analysis/analysisDefaultSettings.m`; put GUI defaults
   in `guiDefaultConfig.m`.
4. Add one dispatch case to `runCadaverDatasetAnalysis.m`. Keep calculations out of
   the dispatcher.
5. Reuse `collectRecords`, `selectTagRows`, and `parseSpectrumExpression`; do not add
   new tag or spectrum parsing inside the analysis module.
6. Add a focused test under `tests`.

Run the tests with:

```matlab
results = runtests('tests');
assertSuccess(results);
```
