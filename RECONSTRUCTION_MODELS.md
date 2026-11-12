# Reconstruction models

In Analysis, choose **Reconstruct**, then **Configure reconstruction**.
Choose a model on **Model and validation**; only that model's settings are used.
No settings or saved predictions are imported from the previous research runs.

## Compact PCA + MLP

Select **Compact PCA + MLP (nested tuning)**. Its dedicated tab exposes:

- Input PCA grid: 5, 10; response PCA components: 5.
- Hidden-neuron grid: 4, 8; weight-penalty grid: 0.1, 1, 10.
- Three inner donor-grouped folds; shuffle seed 20260928.
- Initialization seeds: 7, 17, 27; maximum 1500 L-BFGS-B iterations.

These are the defaults of the tested compact model. The first initialization
is used for inner tuning, minimizing donor-weighted spectral MSE. Selected
parameters are refitted with every seed and their predictions are averaged.
Input/response standardization, PCA, and PCA-score scaling are learned anew
within every training split. The outer test donor is excluded throughout.
This implementation uses the checked multiresponse objective, not sklearn's
MLPRegressor and not MATLAB's original full-spectrum fitnet model.

The Python path defaults to the existing T-score Python environment. It needs
NumPy, SciPy and threadpoolctl. Failure is reported; no fallback model is used.
Convergence warnings appear in the command window and saved diagnostics.
If component counts exceed a training split's numerical rank, reduce them;
the model does not silently truncate the requested architecture.

## Reproduce the tested spectral inputs

- Paired cadavers; tags D2P1_MM00 and D3P1_MM00.
- Intact columns **2, 3**, combination **Difference (second - first)**:
  normalized 6-mm minus normalized 3-mm spectra.
- Reconstruct exposed columns **1, 2, 3 jointly**.
- Both input and exposed-target normalization: **CH2 / peak**.
- Include the same 38-donor cohort and three diagnostic categories.

Changing the cohort, tags, normalization or jointly reconstructed offsets
changes the fitted model. Reconstructing only 3 and 6 mm is not equivalent
to training jointly on all three exposed offsets.

## Kernel ridge (RBF)

Select **Kernel ridge (RBF)**; tested defaults are alpha **0.01** and gamma
multiplier **0.03**. Gamma is the multiplier divided by the median positive
squared distance between standardized training rows. This is a fixed-parameter
alternative, not the compact neural network. Use the same spectral inputs above.

## Original MLP and PLS

The earlier MLP remains labeled **Original full-spectrum MLP (fitnet)** for
reproducibility. Its neuron/epoch/regularization settings do not control the
compact PCA + MLP. Existing PLS settings and algorithms are unchanged.

## Outputs and interpretation

Choose an analysis output directory. Each new run saves settings, metrics and
`predictedCadavers.mat` (measured E/intact T preserved, reconstructions in P).
Compact runs additionally save `reconstruction_tuning.json`: candidate losses,
selected parameters, donor splits, initialization diagnostics, software versions
and backend hash. Saved MAT reconstruction metadata also records each donor's fit.

The favorable earlier ratio comparisons were for **D3P1** normal versus
osteoporosis groups. They are exploratory findings, not a guarantee for every
location, category contrast or new cohort. Model tuning never uses category
p-values. Saved outer-LOCO spectra are not a substitute for refitting
reconstruction inside downstream T-score validation folds.
