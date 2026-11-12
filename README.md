# BoneSORS

BoneSORS is a MATLAB GUI for analyzing spatially offset Raman spectra from bone. It supports dataset preparation, Raman band and spectral comparisons, exposed-bone spectral reconstruction, and research models for wrist DXA T-score prediction.

## Requirements

- MATLAB R2026a is the release used for validation. Earlier releases have not been verified.
- Statistics and Machine Learning Toolbox for the statistical and native T-score workflows.
- Deep Learning Toolbox for CNN prediction and the native neural-network modes that use `fitnet`.
- Python is required only for **Compact PCA + MLP reconstruction** and **matched nested-CV SVR**. See [Python setup](#optional-python-setup).

## Quick start

In MATLAB, change the current folder to this repository and run:

```matlab
BoneSORS
```

To try the GUI with synthetic data, run the following from the same folder:

```matlab
addpath('examples')
[dataset, categories] = makeSyntheticDemo(fullfile(tempdir, 'bonesors-demo'));
BoneSORS
```

In **Dataset Analysis**, load the MAT file printed by the example, then load its category workbook. Choose **Category-average spectra**, select exposed tissue and location `D3P1_MM00`, and enter `1,2,3` for separate 0, 3, and 6 mm panels. Choose a local output folder if prompted, then click **Run selected analysis**.

## Use your own data

- **Individual Cadavers** accepts processed specimen MAT files. This tab prepares a cohort dataset or spectra table for the analysis tab.
- Dataset preparation starts with no specimen-specific exclusion list. Apply your study's quality-control criteria before analysis.
- See [Pair and Save](GUI_GUIDE.md#pair-and-save-create-mat-dataset) to select acquisition tags, exclude specimens or spectra, and save the cohort.
- **Dataset Analysis** accepts a generated cohort MAT file, spectra table, or saved LOCO results, depending on the analysis mode. Load a category workbook for category comparisons or T-score analyses. The synthetic workbook demonstrates the identifier and wrist DXA column names.
- The app uses processed spectra. The synthetic example illustrates the file format and workflow. Its values are artificial and have no scientific or clinical interpretation.

The [GUI reference](GUI_GUIDE.md) describes spectrum expressions, tissue and location selection, model settings, and outputs.

## Optional Python setup

Create a Python 3.12 environment and install the packages:

```sh
python -m venv .venv
```

Install the dependencies with the new environment's interpreter.

```powershell
# Windows PowerShell
.\.venv\Scripts\python.exe -m pip install -r requirements-python.txt
```

```sh
# macOS or Linux
./.venv/bin/python -m pip install -r requirements-python.txt
```

Enter its full executable path in **Configure reconstruction → Compact PCA + MLP → Python executable** or **Configure T-score prediction → Validation → SVR Python**, as appropriate. You can also set `BONESORS_PYTHON` to that path before launching MATLAB. Each backend runs locally.

## Repository layout and tests

- `BoneSORS.m` launches the application.
- `app/` contains the application functions and optional Python backends.
- `app/analysis/` contains the cohort analysis workflows and matched SVR backend.
- `app/compact_mlp_reconstruct.py` implements the compact reconstruction backend.
- `examples/` contains a synthetic dataset generator.
- `tests/` contains regression tests and a numerical PLS fixture.

```matlab
results = runtests('tests');
disp(table(results))
```

Run the Python backend tests with `<venv-python> -m unittest discover -s tests -p "test_*.py"`. Set `BONESORS_PYTHON` for the MATLAB integration test that calls matched SVR.

Related notes: [reconstruction models](RECONSTRUCTION_MODELS.md), [matched T-score validation](MATCHED_TSCORE_README.md), and [ridge regression](RIDGE_TSCORE_README.md).
