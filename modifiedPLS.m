function modifiedPLS(cads, saveDir, reconstructionModelOverride, configOverride)
% modifiedPLS  Reconstruct exposed bone spectra from paired intact spectra.
%
% This is a cleaner paired-cadaver version of PLS.m. It uses the paired
% cadaver file, predicts exposed spectra from selected intact spectra, and
% saves one *_P.mat file per cadaver in the selected output folder.
%
% GUI calls supply configOverride from Configure reconstruction. The local
% settings below remain only for older direct calls without that argument.
% Reconstruction uses outer leave-one-cadaver-out validation. Automatic PLS
% components use inner cadaver-wise LOCO with training-fold-only scaling.

% ========================= USER SETTINGS =========================

% Change this path when you want to run a different pairedCadavers file.
% Leave empty ("") if you prefer to choose the file when the function runs.
pairedCadaversFile = "";

% Change this path when you want to save outputs somewhere else.
% Leave empty ("") to save beside pairedCadaversFile.
outputFolder = "";

% Tags to use from each cadaver. Empty {} means use every paired row.
% For the updated dataset, this keeps the central measurements from D2/D3.
%tagsToUse = {'D2P1_MM00','D3P1_MM00','D3P2_MM00'};
% To test more rows step-by-step:
%   add 03s:
%     {'D2P1_MM00','D3P1_MM00','D3P2_MM00', ...
%      'D2P1_MP03','D2P1_MD03','D3P1_MP03','D3P1_MD03','D3P2_MP03','D3P2_MD03'}
%   then add 05s:
%     plus 'D2P1_MP05','D2P1_MD05','D3P1_MP05','D3P1_MD05','D3P2_MP05','D3P2_MD05'
%tagsToUse = {'D2P1_MM00','D3P1_MM00','D3P1_MD03','D3P1_MP03'};
% % tagsToUse = {'D2P1_MM00','D3P1_MM00','D3P2_MM00', ...
% %      'D2P1_MP03','D2P1_MD03','D3P1_MP03','D3P1_MD03','D3P2_MP03','D3P2_MD03'};
tagsToUse = {'D2P1_MM00','D3P1_MM00'};
%tagsToUse = {'D3P1_MM00'};


% WHO categories to include. Empty {} means use all saved categories.
% For two-class testing, remove osteopenia like this:
categoriesToUse = {'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
%categoriesToUse = {'NORMAL','OSTEOPOROSIS'};
%categoriesToUse = {};

% Intact/transcutaneous spectra used as predictors:
%   [3]     -> 6 mm only
%   [2 3]   -> 3 mm and 6 mm       (recommended default)
%   [1 2 3] -> 0 mm, 3 mm, and 6 mm
intactSpectraToUse = [2 3];

% How to combine the selected intact spectra:
%   "concat"    -> original behavior, append selected spectra side by side
%   "mean"      -> mean of selected spectra
%   "diff"      -> second selected spectrum - first selected spectrum
%   "meanDiff"  -> mean plus difference
combineMode = "diff";

% Optional normalization inside modifiedPLS. Keep pairAndSave unnormalized,
% then change these settings here when testing model configurations.
%   normalizationRegion = "none" skips normalization.
%   Otherwise use: "PO4", "CO3", "CH2", "AmideI", "AmideIII", "FullSpectrum"
normalizationRegion = "CH2";
normalizationMethod = "peak";       % "peak", "peakBaseline", or "area"
normalizePredictors = true;         % intact/transcutaneous spectra
normalizeResponse = true;          % exposed spectra being reconstructed

% Exposed spectrum column(s) to reconstruct:
%   1 -> exposed 0 mm on bone
%   2 -> exposed 3 mm on bone
%   [1 2] -> reconstruct both, then analyze spectrum 2 alone or combine
%            [1 2] in analyzePairedCadavers/displayMetrics.
exposedSpectrumToPredict = [1 2];

% Use a fixed component count from the best recent analysis, or set true to
% choose nopt separately inside each leave-one-cadaver-out training set.
useInnerCVForNComponents = 0;
fixedNComponents = 8;
maxComponentsForCV = 15;

% Reconstruction model:
%   "PLS" -> original partial least squares reconstruction
%   "MLP" -> multi-layer perceptron reconstruction using fitnet
%   "KRR_RBF" -> nonlinear multi-response kernel ridge reconstruction
%   "PCA_MLP" -> compact PCA/tanh network, nested donor CV, seed ensemble
reconstructionModel = "PLS";
plsAlgorithm = "NIPALS"; % Python-compatible; SIMPLS reproduces older MATLAB runs.
plsMaxIterations = 5000;
plsTolerance = 1e-6;
mlpHiddenLayerSizes = 24;
mlpTrainFcn = "trainscg";
mlpMaxEpochs = 900;
mlpRegularization = 0.10;

% KRR_RBF settings. Gamma uses the same median-distance convention as the
% Python sweep: gamma = krrGammaMultiplier / median(||xi-xj||^2).
krrAlpha = 0.01;
krrGammaMultiplier = 0.03;

% R04191 standardizes X/Y using training-fold sample SD (ddof=1), then fits
% sklearn PLSRegression(scale=false). NIPALS + these scales matches that fit.
standardizeBeforePLS = 1;

% After saving each file, reload it and confirm the saved spectra equal the
% exact Ypred spectra used for metrics.
verifySavedFiles = true;

% Output format:
%   "individual" -> one *_P.mat file per cadaver, same as before
%   "single"     -> one predictedCadavers.mat file with variable cads.
%                   In this file, measured exposed spectra remain in E and
%                   reconstructed spectra are saved separately in P.
%   "both"       -> save both formats
saveOutputMode = "both";
combinedOutputFileName = "predictedCadavers.mat";

metricsFileName = "modifiedPLS_metrics.csv";

% ======================= END USER SETTINGS =======================

% The GUI supplies a complete, validated configuration; legacy calls retain
% the editable defaults above. Never read reconstruction options from T-score controls.
responseNormalizationRegion = normalizationRegion;
responseNormalizationMethod = normalizationMethod;
randomSeed = 7;
compactConfig = reconstructionDefaultConfig();
if nargin >= 4 && ~isempty(configOverride)
    cfg = validateReconstructionConfiguration(configOverride);
    compactConfig = cfg;
    tagsToUse = cfg.tagsToUse;
    categoriesToUse = cfg.categoriesToUse;
    intactSpectraToUse = cfg.intactSpectraToUse;
    combineMode = cfg.combineMode;
    exposedSpectrumToPredict = cfg.exposedSpectrumToPredict;
    normalizationRegion = cfg.normalizationRegion;
    normalizationMethod = cfg.normalizationMethod;
    responseNormalizationRegion = cfg.responseNormalizationRegion;
    responseNormalizationMethod = cfg.responseNormalizationMethod;
    normalizePredictors = cfg.normalizationRegion ~= "none";
    normalizeResponse = cfg.responseNormalizationRegion ~= "none";
    reconstructionModel = cfg.reconstructionModel;
    plsAlgorithm = cfg.plsAlgorithm;
    plsMaxIterations = cfg.plsMaxIterations;
    plsTolerance = cfg.plsTolerance;
    useInnerCVForNComponents = cfg.useInnerCVForNComponents;
    fixedNComponents = cfg.fixedNComponents;
    maxComponentsForCV = cfg.maxComponentsForCV;
    standardizeBeforePLS = cfg.standardizeBeforePLS;
    mlpHiddenLayerSizes = cfg.mlpHiddenLayerSizes;
    mlpTrainFcn = cfg.mlpTrainFcn;
    mlpMaxEpochs = cfg.mlpMaxEpochs;
    mlpRegularization = cfg.mlpRegularization;
    randomSeed = cfg.randomSeed;
    krrAlpha = cfg.krrAlpha;
    krrGammaMultiplier = cfg.krrGammaMultiplier;
    verifySavedFiles = cfg.verifySavedFiles;
    saveOutputMode = cfg.saveOutputMode;
    combinedOutputFileName = cfg.combinedOutputFileName;
    metricsFileName = cfg.metricsFileName;
end
previousRng = rng;
rngCleanup = onCleanup(@()rng(previousRng)); %#ok<NASGU>
rng(randomSeed,'twister');

%%

if nargin < 1 || isempty(cads)
    [cads, pairedCadaversFile] = localLoadPairedCadavers(pairedCadaversFile);
else
    pairedCadaversFile = "";
end

if nargin < 2 || isempty(saveDir)
    if strlength(outputFolder) == 0
        if strlength(pairedCadaversFile) > 0
            saveDir = fileparts(char(pairedCadaversFile));
        else
            saveDir = uigetdir(pwd, 'Select folder for predicted *_P.mat files');
            if isequal(saveDir, 0)
                error('Output folder is required.');
            end
        end
    else
        saveDir = char(outputFolder);
    end
end

if nargin >= 3 && ~isempty(reconstructionModelOverride)
    reconstructionModel = string(reconstructionModelOverride);
end

if ~exist(saveDir, 'dir')
    mkdir(saveDir);
end

normalizationRegion = validatestring(normalizationRegion, ...
    {'none','PO4','CO3','CH2','AmideI','AmideIII','FullSpectrum'});
normalizationMethod = validatestring(normalizationMethod, {'peak','peakBaseline','area'});
saveOutputMode = validatestring(saveOutputMode, {'individual','single','both'});
reconstructionModel = validatestring(reconstructionModel, {'PLS','MLP','KRR_RBF','PCA_MLP'});

cads = localFilterCadaversByCategory(cads, categoriesToUse);
if isempty(cads)
    error('No cadavers were found.');
end

nCad = numel(cads);
if nCad < 3, error('MainGUI:ReconstructionData','At least three cadavers are required.'); end
if numel(unique(string({cads.id}))) ~= nCad
    error('MainGUI:ReconstructionData','Cadaver IDs must be unique to enforce cadaver-wise validation.');
end
wnLen = numel(cads(1).wn);
for k = 1:nCad
    if ~isequal(double(cads(k).wn(:)),double(cads(1).wn(:)))
        error('MainGUI:ReconstructionData','All cadavers must have the same wavenumber grid.');
    end
end
if strcmpi(reconstructionModel,'MLP') && exist('fitnet','file') ~= 2
    error('MainGUI:ReconstructionMLPUnavailable', ...
        'The configured MLP requires fitnet. Install/enable Deep Learning Toolbox or choose PLS/KRR; no silent fallback will be used.');
end

allRMSE = nan(nCad, 1);
allR = nan(nCad, 1);
allNopt = nan(nCad, 1);
allRows = nan(nCad, 1);
P_toSave = cell(nCad, 1);

fprintf('\n=== modifiedPLS paired-cadaver reconstruction ===\n');
fprintf('Cadavers: %d\n', nCad);
fprintf('Categories used: %s\n', localTagListText(categoriesToUse));
fprintf('Tags used: %s\n', localTagListText(tagsToUse));
fprintf('Intact spectra used: %s\n', mat2str(intactSpectraToUse));
fprintf('Combine mode: %s\n', combineMode);
fprintf('Normalization: predictors=%d response=%d region=%s method=%s\n', ...
    normalizePredictors, normalizeResponse, normalizationRegion, normalizationMethod);
fprintf('Exposed spectrum predicted: %s\n', mat2str(exposedSpectrumToPredict));
fprintf('Response normalization: %s / %s (enabled=%d)\n', ...
    responseNormalizationRegion,responseNormalizationMethod,normalizeResponse);
fprintf('Reconstruction model: %s\n', reconstructionModel);
if reconstructionModel == "PLS"
    fprintf('PLS algorithm: %s (NIPALS max iterations=%d, tolerance=%g)\n', ...
        plsAlgorithm,plsMaxIterations,plsTolerance);
end
if strcmpi(reconstructionModel, 'KRR_RBF')
    fprintf('KRR_RBF alpha: %.4g   gamma multiplier: %.4g\n', krrAlpha, krrGammaMultiplier);
end
fprintf('Output folder: %s\n\n', saveDir);

if strcmpi(reconstructionModel,'PCA_MLP')
    compactConfig.reconstructionModel = "PCA_MLP";
    [compactX,compactY,compactTags,compactIDs] = localBuildMatrices( ...
        cads,1:nCad,intactSpectraToUse,exposedSpectrumToPredict,tagsToUse, ...
        combineMode,normalizePredictors,normalizeResponse,normalizationRegion, ...
        normalizationMethod,responseNormalizationRegion,responseNormalizationMethod);
    [compactPredictions,compactDiagnostics] = predictCompactReconstruction( ...
        compactX,compactY,compactIDs,compactConfig,saveDir);
end

for k = 1:nCad
    [Xtrain, Ytrain, ~, trainIDs] = localBuildMatrices( ...
        cads, setdiff(1:nCad, k), intactSpectraToUse, exposedSpectrumToPredict, ...
        tagsToUse, combineMode, normalizePredictors, normalizeResponse, ...
        normalizationRegion, normalizationMethod, responseNormalizationRegion, responseNormalizationMethod);

    [Xtest, Ytrue, testTags] = localBuildMatrices( ...
        cads, k, intactSpectraToUse, exposedSpectrumToPredict, ...
        tagsToUse, combineMode, normalizePredictors, normalizeResponse, ...
        normalizationRegion, normalizationMethod, responseNormalizationRegion, responseNormalizationMethod);

    if isempty(Xtest)
        warning('Cadaver %s has no usable paired rows. Skipping.', cads(k).id);
        continue
    end

    if isempty(Xtrain)
        error('No training rows remain after excluding cadaver %s.', cads(k).id);
    end

    if strcmpi(reconstructionModel,'PCA_MLP')
        rows = string(compactIDs)==string(cads(k).id);
        assert(isequal(string(compactTags(rows)),string(testTags)), ...
            'MainGUI:CompactRowOrder','Compact prediction tags do not match test rows.');
        Ypred = compactPredictions(rows,:);
        ncomp = compactConfig.compactOutputPCs;
        fold = find(string({compactDiagnostics.folds.held_out})==string(cads(k).id),1);
        assert(~isempty(fold),'MainGUI:CompactFold','Missing held-out donor diagnostics.');
        plsInfo = struct();
    else
        [Ypred, ncomp, plsInfo] = localFitPredictReconstruction(Xtrain, Ytrain, Xtest, ...
        reconstructionModel, useInnerCVForNComponents, fixedNComponents, ...
        maxComponentsForCV, standardizeBeforePLS, mlpHiddenLayerSizes, ...
        mlpTrainFcn, mlpMaxEpochs, mlpRegularization, ...
        krrAlpha, krrGammaMultiplier, trainIDs, plsAlgorithm, plsMaxIterations, plsTolerance);
    end

    [rmseVec, rVec] = evalMetrics(Ypred, Ytrue);
    allRMSE(k) = mean(rmseVec, 'omitnan');
    allR(k) = mean(rVec, 'omitnan');
    allNopt(k) = ncomp;
    allRows(k) = size(Xtest, 1);

    P = struct();
    P.usedSpectra = exposedSpectrumToPredict;
    P.wavenum = double(cads(k).wn(:));
    P.anitaspec = localPredictionRowsToCells(Ypred, wnLen, exposedSpectrumToPredict);
    P.list = cellstr(strcat(string(cads(k).id), "_P_", testTags(:)));
    P.processoptions = struct();
    P.processoptions.method = "modifiedPLS";
    P.processoptions.reconstructionModel = reconstructionModel;
    P.processoptions.plsFit = plsInfo;
    if strcmpi(reconstructionModel,'PCA_MLP')
        P.processoptions.compactFit = compactDiagnostics.folds(fold);
        P.processoptions.compactConfiguration = compactConfig;
        P.processoptions.componentCountMeaning = "response PCA components (not PLS)";
    end
    P.processoptions.mlpHiddenLayerSizes = mlpHiddenLayerSizes;
    P.processoptions.mlpTrainFcn = mlpTrainFcn;
    P.processoptions.mlpMaxEpochs = mlpMaxEpochs;
    P.processoptions.mlpRegularization = mlpRegularization;
    P.processoptions.krrAlpha = krrAlpha;
    P.processoptions.krrGammaMultiplier = krrGammaMultiplier;
    P.processoptions.validation = "leave-one-cadaver-out";
    P.processoptions.intactSpectraUsed = intactSpectraToUse;
    P.processoptions.tagsToUse = tagsToUse;
    P.processoptions.categoriesToUse = categoriesToUse;
    P.processoptions.combineMode = combineMode;
    P.processoptions.normalizationRegion = normalizationRegion;
    P.processoptions.normalizationMethod = normalizationMethod;
    P.processoptions.responseNormalizationRegion = responseNormalizationRegion;
    P.processoptions.responseNormalizationMethod = responseNormalizationMethod;
    P.processoptions.randomSeed = randomSeed;
    P.processoptions.innerComponentSelection = logical(useInnerCVForNComponents);
    if strcmpi(reconstructionModel,'PCA_MLP')
        P.processoptions.innerComponentSelection = true;
        P.processoptions.innerValidation = "donor-grouped K-fold; training-only scaling/PCA";
        P.processoptions.selectionMetric = "donor-weighted spectral MSE (no category labels)";
    end
    P.processoptions.trainingCadaverIDs = unique(trainIDs,'stable');
    P.processoptions.heldOutCadaver = string(cads(k).id);
    P.processoptions.normalizePredictors = normalizePredictors;
    P.processoptions.normalizeResponse = normalizeResponse;
    P.processoptions.exposedSpectrumPredicted = exposedSpectrumToPredict;
    P.processoptions.nComponents = ncomp;
    P.processoptions.standardizeBeforePLS = standardizeBeforePLS;
    P.processoptions.trainingCadavers = numel(unique(trainIDs));
    P.processoptions.pairedCadaversFile = pairedCadaversFile;

    P_toSave{k} = P;

    fprintf(' Cadaver %-12s : rows = %3d   ncomp = %2d   mean RMSE = %.4f   mean r = %.4f\n', ...
        cads(k).id, size(Xtest, 1), ncomp, allRMSE(k), allR(k));
end

valid = isfinite(allRMSE) & isfinite(allR);
if all(cellfun(@isempty,P_toSave))
    error('MainGUI:ReconstructionData','No usable paired rows matched the chosen tags, spectra and categories.');
end

fprintf('\n=== modifiedPLS summary =====================================\n');
fprintf('Overall mean RMSE = %.4f +/- %.4f\n', mean(allRMSE(valid)), std(allRMSE(valid)));
fprintf('Overall mean r    = %.4f +/- %.4f\n', mean(allR(valid)), std(allR(valid)));
fprintf('=============================================================\n\n');

if any(strcmpi(saveOutputMode, {'individual','both'}))
    for k = 1:nCad
        if isempty(P_toSave{k})
            continue
        end

        process = P_toSave{k}; %#ok<NASGU>
        fileName = fullfile(saveDir, [char(cads(k).id) '_P.mat']);
        save(fileName, 'process');

        if verifySavedFiles
            Scheck = load(fileName, 'process');
            maxDiff = localMaxProcessSpectrumDiff(process, Scheck.process);
            if maxDiff > 1e-10
                error('MainGUI:ReconstructionSaveVerification', ...
                    'Saved file %s differs from in-memory prediction. Max difference = %.3g', fileName, maxDiff);
            end
        end
    end
end

if any(strcmpi(saveOutputMode, {'single','both'}))
    cadsPred = localBuildPredictedCadaverStruct(cads, P_toSave);
    cadsPred = localOrderPredictedCadaverFields(cadsPred);
    cadsOriginalForMetrics = cads;
    cads = cadsPred; %#ok<NASGU>
    combinedFile = fullfile(saveDir, char(combinedOutputFileName));
    reconstructionInfo = P_toSave; %#ok<NASGU>
    save(combinedFile, 'cads', 'reconstructionInfo', '-v7');
    if verifySavedFiles
        checked = load(combinedFile,'cads');
        if ~isequaln(checked.cads,cads)
            error('MainGUI:ReconstructionSaveVerification','Combined MAT verification failed.');
        end
    end
    cads = cadsOriginalForMetrics;
    fprintf('Saved combined predicted cadaver file: %s\n', combinedFile);
end

cadNames = string({cads.id}).';
T = table(cadNames, allRMSE, allR, allNopt, allRows, ...
    repmat({intactSpectraToUse}, nCad, 1), ...
    repmat({tagsToUse}, nCad, 1), ...
    repmat({categoriesToUse}, nCad, 1), ...
    repmat(string(combineMode), nCad, 1), ...
    repmat(string(normalizationRegion), nCad, 1), ...
    repmat(string(normalizationMethod), nCad, 1), ...
    repmat(normalizePredictors, nCad, 1), ...
    repmat(normalizeResponse, nCad, 1), ...
    repmat({exposedSpectrumToPredict}, nCad, 1), ...
    repmat(string(reconstructionModel), nCad, 1), ...
    'VariableNames', {'Cadaver', 'MeanRMSE', 'MeanR', 'nComponents', ...
    'nPredictedRows', 'IntactSpectraUsed', 'TagsToUse', 'CategoriesToUse', 'CombineMode', ...
    'NormalizationRegion', 'NormalizationMethod', 'NormalizePredictors', 'NormalizeResponse', ...
    'ExposedSpectrumPredicted', 'ReconstructionModel'});

overallRow = table("Overall", mean(allRMSE(valid)), mean(allR(valid)), NaN, sum(allRows(valid)), ...
    {intactSpectraToUse}, {tagsToUse}, {categoriesToUse}, string(combineMode), ...
    string(normalizationRegion), string(normalizationMethod), normalizePredictors, normalizeResponse, ...
    {exposedSpectrumToPredict}, string(reconstructionModel), ...
    'VariableNames', T.Properties.VariableNames);
T = [T; overallRow];

writetable(T, fullfile(saveDir, metricsFileName));
fprintf('Saved outputs for %d predicted cadavers and metrics table: %s\n', nnz(valid), fullfile(saveDir, metricsFileName));

end


function [cads, pairedCadaversFile] = localLoadPairedCadavers(pairedCadaversFile)
if strlength(pairedCadaversFile) == 0
    [fileName, folderName] = uigetfile('*.mat', 'Select pairedCadavers.mat');
    if isequal(fileName, 0)
        error('pairedCadavers.mat is required.');
    end
    pairedCadaversFile = string(fullfile(folderName, fileName));
end

S = load(char(pairedCadaversFile));
if isfield(S, 'cads')
    cads = S.cads;
elseif isfield(S, 'pairedCadavers')
    cads = S.pairedCadavers;
else
    error('Selected file does not contain cads or pairedCadavers.');
end
end


function [Ypred, ncomp, plsInfo] = localFitPredictReconstruction(Xtrain, Ytrain, Xtest, ...
    reconstructionModel, useInnerCVForNComponents, fixedNComponents, ...
    maxComponentsForCV, standardizeBeforePLS, mlpHiddenLayerSizes, ...
    mlpTrainFcn, mlpMaxEpochs, mlpRegularization, ...
    krrAlpha, krrGammaMultiplier, trainIDs, plsAlgorithm, plsMaxIterations, plsTolerance)

plsInfo = struct();
switch string(reconstructionModel)
    case "PLS"
        if useInnerCVForNComponents
            ncomp = localChooseNComponents(Xtrain, Ytrain, maxComponentsForCV, trainIDs, standardizeBeforePLS, ...
                plsAlgorithm, plsMaxIterations, plsTolerance);
        else
            ncomp = min([fixedNComponents, size(Xtrain, 1) - 1, size(Xtrain, 2), size(Ytrain, 2)]);
        end

        if ncomp < 1, error('MainGUI:ReconstructionData','Insufficient training rows for PLS.'); end
        if standardizeBeforePLS
            [XtrainPLS, xMu, xSigma] = localAutoscale(Xtrain);
            [YtrainPLS, yMu, ySigma] = localAutoscale(Ytrain);
            XtestPLS = (Xtest - xMu) ./ xSigma;

            [YpredScaled, plsInfo] = fitReconstructionPLS(XtrainPLS, YtrainPLS, XtestPLS, ncomp, ...
                plsAlgorithm, plsMaxIterations, plsTolerance);
            Ypred = (YpredScaled .* ySigma) + yMu;
        else
            [Ypred, plsInfo] = fitReconstructionPLS(Xtrain, Ytrain, Xtest, ncomp, ...
                plsAlgorithm, plsMaxIterations, plsTolerance);
        end

    case "MLP"
        ncomp = sum(mlpHiddenLayerSizes);
        [XtrainMLP, xMu, xSigma] = localAutoscale(Xtrain);
        [YtrainMLP, yMu, ySigma] = localAutoscale(Ytrain);
        XtestMLP = (Xtest - xMu) ./ xSigma;

        YpredScaled = localFitPredictMLP(XtrainMLP, YtrainMLP, XtestMLP, ...
            mlpHiddenLayerSizes, mlpTrainFcn, mlpMaxEpochs, mlpRegularization);
        Ypred = (YpredScaled .* ySigma) + yMu;

    case "KRR_RBF"
        ncomp = 0;
        [XtrainKRR, xMu, xSigma] = localAutoscale(Xtrain);
        [YtrainKRR, yMu, ySigma] = localAutoscale(Ytrain);
        XtestKRR = (Xtest - xMu) ./ xSigma;

        YpredScaled = localFitPredictKRRRBF(XtrainKRR, YtrainKRR, XtestKRR, ...
            krrAlpha, krrGammaMultiplier);
        Ypred = (YpredScaled .* ySigma) + yMu;
end
end


function cadsOut = localFilterCadaversByCategory(cadsIn, categoriesToUse)
if isempty(categoriesToUse)
    cadsOut = cadsIn;
    return
end

categoriesToUse = upper(strtrim(string(categoriesToUse)));
keep = false(size(cadsIn));
hasCategory = false(size(cadsIn));

for ii = 1:numel(cadsIn)
    category = localCadaverCategory(cadsIn(ii));
    hasCategory(ii) = strlength(category) > 0;
    keep(ii) = strlength(category) > 0 && any(category == categoriesToUse);
end

if ~any(hasCategory)
    warning(['No WHO classification field was found in the selected paired-cadaver file. ', ...
        'Category filtering was skipped.']);
    cadsOut = cadsIn;
    return
end

cadsOut = cadsIn(keep);
end


function category = localCadaverCategory(cad)
category = "";
fields = string(fieldnames(cad));
hits = [find(contains(fields,"WHOClassification","IgnoreCase",true)); find(strcmpi(fields,'category'))];
for hit = hits(:).'
    value = cad.(char(fields(hit)));
    if iscell(value) && numel(value)==1, value=value{1}; end
    if ischar(value) || (isstring(value) && isscalar(value))
        candidate = upper(strtrim(string(value)));
        if strlength(candidate)>0, category=candidate; return, end
    end
end
end


function [X, Y, tags, ids] = localBuildMatrices(cads, cadIdx, intactSpectraToUse, exposedSpectrumToPredict, ...
    tagsToUse, combineMode, normalizePredictors, normalizeResponse, normalizationRegion, normalizationMethod, ...
    responseNormalizationRegion, responseNormalizationMethod)
X = [];
Y = [];
tags = strings(0, 1);
ids = strings(0,1);
combineMode = validatestring(combineMode, {'concat','mean','add','diff','meanDiff'});

for ii = 1:numel(cadIdx)
    c = cadIdx(ii);
    E = localAsCell(cads(c).E);
    T = localAsCell(cads(c).T);
    listRows = localListRows(cads(c).list);

    nRows = min(numel(E), numel(T));
    for s = 1:nRows
        Emat = E{s};
        Tmat = T{s};

        if isempty(Emat) || isempty(Tmat)
            continue
        end
        if size(Emat, 2) < max(exposedSpectrumToPredict) || size(Tmat, 2) < max(intactSpectraToUse)
            continue
        end

        if s <= size(listRows, 1)
            tag = localTagFromName(listRows{s, 1});
        else
            tag = "Row" + s;
        end

        if ~localKeepTag(tag, tagsToUse)
            continue
        end

        wn = double(cads(c).wn(:));
        Twork = localMaybeNormalizeSpectra(wn, Tmat, normalizePredictors, ...
            normalizationRegion, normalizationMethod);
        Ework = localMaybeNormalizeSpectra(wn, Emat, normalizeResponse, ...
            responseNormalizationRegion, responseNormalizationMethod);

        Xrow = localBuildPredictorRow(Twork, intactSpectraToUse, combineMode);
        Yrow = localBuildResponseRow(Ework, exposedSpectrumToPredict);
        if any(~isfinite(Xrow)) || any(~isfinite(Yrow))
            error('MainGUI:ReconstructionData','Nonfinite selected spectral values for cadaver %s, tag %s.',cads(c).id,tag);
        end
        X = [X; Xrow]; %#ok<AGROW>
        Y = [Y; Yrow]; %#ok<AGROW>
        tags(end + 1, 1) = tag; %#ok<AGROW>
        ids(end + 1, 1) = string(cads(c).id); %#ok<AGROW>
    end
end
end


function Swork = localMaybeNormalizeSpectra(wn, S, doNormalize, normalizationRegion, normalizationMethod)
if ~doNormalize || strcmpi(string(normalizationRegion), "none")
    Swork = S;
    return
end

Swork = double(S);
for col = 1:size(S,2)
    Swork(:,col) = normalizeSpectra(wn,double(S(:,col)), ...
        char(normalizationRegion),char(normalizationMethod));
end
end


function keep = localKeepTag(tag, tagsToUse)
if isempty(tagsToUse)
    keep = true;
    return
end

tag = string(tag);
tagsToUse = string(tagsToUse);
keep = any(strcmpi(tag, tagsToUse));
end


function Xrow = localBuildPredictorRow(Tmat, intactSpectraToUse, combineMode)
selected = Tmat(:, intactSpectraToUse);

switch string(combineMode)
    case "concat"
        Xrow = reshape(selected, 1, []);

    case "mean"
        Xrow = mean(selected, 2, 'omitnan').';

    case "add"
        Xrow = sum(selected,2).';

    case "diff"
        if numel(intactSpectraToUse) == 1
            Xrow = selected.';
        elseif numel(intactSpectraToUse) == 2
            Xrow = (selected(:, 2) - selected(:, 1)).';
        else
            error('combineMode = "diff" requires one or two intact spectra.');
        end

    case "meanDiff"
        if numel(intactSpectraToUse) ~= 2
            error('combineMode = "meanDiff" requires exactly two intact spectra.');
        end
        meanPart = mean(selected, 2, 'omitnan').';
        diffPart = (selected(:, 2) - selected(:, 1)).';
        Xrow = [meanPart, diffPart];
end
end


function Yrow = localBuildResponseRow(Emat, exposedSpectrumToPredict)
selected = Emat(:, exposedSpectrumToPredict);
Yrow = reshape(selected, 1, []);
end


function spectraCells = localPredictionRowsToCells(Ypred, wnLen, exposedSpectrumToPredict)
spectraCells = cell(size(Ypred, 1), 1);
nExposedTargets = numel(exposedSpectrumToPredict);
maxExposedTarget = max(exposedSpectrumToPredict);
for ii = 1:size(Ypred, 1)
    compactPred = reshape(Ypred(ii, :), wnLen, nExposedTargets);
    fullPred = nan(wnLen, maxExposedTarget);
    fullPred(:, exposedSpectrumToPredict) = compactPred;
    spectraCells{ii} = fullPred;
end
end


function cadsPred = localBuildPredictedCadaverStruct(cadsOriginal, P_toSave)
if ~isfield(cadsOriginal,'P'), [cadsOriginal.P] = deal({}); end
if ~isfield(cadsOriginal,'WHOClassification_DistalRadius_1_3_')
    [cadsOriginal.WHOClassification_DistalRadius_1_3_] = deal("");
end
cadsPred = cadsOriginal([]);
writeIdx = 0;

for ii = 1:numel(P_toSave)
    if isempty(P_toSave{ii})
        continue
    end

    writeIdx = writeIdx + 1;
    cadsPred(writeIdx) = cadsOriginal(ii);
    P = P_toSave{ii};
    nRows = numel(P.anitaspec);

    cadsPred(writeIdx).id = cadsOriginal(ii).id; %#ok<AGROW>
    cadsPred(writeIdx).wn = P.wavenum(:);
    cadsPred(writeIdx).T = cell(nRows, 1);
    cadsPred(writeIdx).E = cell(nRows, 1);
    cadsPred(writeIdx).P = P.anitaspec(:);
    cadsPred(writeIdx).list = cell(nRows, 3);
    cadsPred(writeIdx).WHOClassification_DistalRadius_1_3_ = localCadaverCategory(cadsOriginal(ii));

    originalE = localAsCell(cadsOriginal(ii).E);
    if isfield(cadsOriginal(ii), 'T')
        originalT = localAsCell(cadsOriginal(ii).T);
    else
        originalT = {};
    end
    originalRows = localListRows(cadsOriginal(ii).list);

    for jj = 1:nRows
        tag = localTagFromPredictedName(P.list{jj});
        originalIdx = localFindTagRow(originalRows, tag, 1);

        if ~isempty(originalIdx) && originalIdx <= numel(originalE)
            cadsPred(writeIdx).E{jj} = originalE{originalIdx};
        else
            cadsPred(writeIdx).E{jj} = [];
        end

        if ~isempty(originalIdx) && originalIdx <= numel(originalT)
            cadsPred(writeIdx).T{jj} = originalT{originalIdx};
        else
            cadsPred(writeIdx).T{jj} = [];
        end

        cadsPred(writeIdx).list{jj, 1} = sprintf('%s_E_%s.mat', char(cadsPred(writeIdx).id), char(tag));
        cadsPred(writeIdx).list{jj, 2} = sprintf('%s_T_%s.mat', char(cadsPred(writeIdx).id), char(tag));
        cadsPred(writeIdx).list{jj, 3} = sprintf('%s_P_%s.mat', char(cadsPred(writeIdx).id), char(tag));
    end
end
end


function cadsPred = localOrderPredictedCadaverFields(cadsPred)
fieldOrder = {'id', 'wn', 'T', 'E', 'P', 'list', ...
    'WHOClassification_DistalRadius_1_3_'};
extraFields = setdiff(fieldnames(cadsPred),fieldOrder,'stable');
cadsPred = orderfields(cadsPred, [fieldOrder(:); extraFields(:)]);
end


function rowIdx = localFindTagRow(listRows, wantedTag, listCol)
rowIdx = [];

if isempty(listRows) || size(listRows, 2) < listCol
    return
end

wantedTag = regexprep(string(wantedTag), '_r\d+$', '');
for rr = 1:size(listRows, 1)
    tag = localTagFromName(listRows{rr, listCol});
    tag = regexprep(string(tag), '_r\d+$', '');
    if strcmpi(tag, wantedTag)
        rowIdx = rr;
        return
    end
end
end


function tag = localTagFromPredictedName(fileName)
tag = regexprep(string(fileName), '^[^_]+_P_(.*)$', '$1');
tag = erase(tag, ".mat");
end


function C = localAsCell(value)
if iscell(value)
    C = value(:);
elseif isnumeric(value) && ismatrix(value)
    C = {value};
else
    C = num2cell(value(:));
end
end


function rows = localListRows(listValue)
if isempty(listValue)
    rows = cell(0, 2);
elseif iscell(listValue)
    if size(listValue, 2) >= 2
        rows = listValue;
    elseif numel(listValue) == 2
        rows = reshape(listValue, 1, 2);
    else
        rows = listValue(:);
    end
else
    rows = cellstr(string(listValue));
    if numel(rows) == 2
        rows = reshape(rows, 1, 2);
    end
end
end


function tag = localTagFromName(fileName)
tag = regexprep(string(fileName), '^[^_]+_[ETP]_(.*)\.mat$', '$1');
tag = erase(tag, ".mat");
end


function text = localTagListText(priorityTags)
if isempty(priorityTags)
    text = "all paired rows";
else
    text = strjoin(string(priorityTags), ", ");
end
end


function nopt = localChooseNComponents(Xtrain, Ytrain, maxComponentsForCV, ids, standardize, algorithm, maxIter, tolerance)
groups = unique(ids,'stable');
if numel(groups)<3
    error('MainGUI:ReconstructionData','Inner LOCO requires at least three outer-training cadavers.');
end
largestGroup = max(arrayfun(@(g)sum(ids==g),groups));
maxComponents = min([maxComponentsForCV, size(Xtrain,1)-largestGroup-1, size(Xtrain,2), size(Ytrain,2)]);
if maxComponents < 1
    error('Not enough training rows for PLS.');
end

loss = nan(numel(groups),maxComponents);
for g = 1:numel(groups)
    test = ids==groups(g); train = ~test;
    A = Xtrain(train,:); B = Ytrain(train,:); Q = Xtrain(test,:);
    if standardize
        [A,xMu,xSigma] = localAutoscale(A);
        [B,yMu,ySigma] = localAutoscale(B);
        Q = (Q-xMu)./xSigma;
    end
    for p = 1:maxComponents
        prediction = fitReconstructionPLS(A,B,Q,p,algorithm,maxIter,tolerance);
        if standardize, prediction = prediction.*ySigma+yMu; end
        delta = prediction-Ytrain(test,:);
        loss(g,p) = mean(delta(:).^2);
    end
end
[~, nopt] = min(mean(loss,1));
end


function [Xscaled, mu, sigma] = localAutoscale(X)
mu = mean(X, 1, 'omitnan');
sigma = std(X, 0, 1, 'omitnan');
sigma(~isfinite(sigma) | sigma == 0) = 1;
Xscaled = (X - mu) ./ sigma;
end


function Ypred = localFitPredictKRRRBF(Xtrain, Ytrain, Xtest, alpha, gammaMultiplier)
if nargin < 4 || isempty(alpha)
    alpha = 0.01;
end
if nargin < 5 || isempty(gammaMultiplier)
    gammaMultiplier = 0.03;
end

if isempty(Xtrain) || isempty(Ytrain)
    error('KRR_RBF reconstruction requires non-empty training matrices.');
end

Xtrain(~isfinite(Xtrain)) = 0;
Ytrain(~isfinite(Ytrain)) = 0;
Xtest(~isfinite(Xtest)) = 0;

Dtrain = localSquaredDistances(Xtrain, Xtrain);
upperMask = triu(true(size(Dtrain)), 1);
offDiag = Dtrain(upperMask);
offDiag = offDiag(isfinite(offDiag) & offDiag > 0);
medianD2 = median(offDiag, 'omitnan');
if ~isfinite(medianD2) || medianD2 <= 0
    medianD2 = max(1, size(Xtrain, 2));
end

gamma = gammaMultiplier / medianD2;
Ktrain = exp(-gamma .* Dtrain);
Ktest = exp(-gamma .* localSquaredDistances(Xtest, Xtrain));

lambda = alpha .* eye(size(Ktrain, 1));
dualCoef = (Ktrain + lambda) \ Ytrain;
Ypred = Ktest * dualCoef;
end


function D2 = localSquaredDistances(A, B)
A2 = sum(A.^2, 2);
B2 = sum(B.^2, 2).';
D2 = A2 + B2 - 2 .* (A * B.');
D2(D2 < 0 & D2 > -1e-10) = 0;
D2 = max(D2, 0);
end


function Ypred = localFitPredictMLP(Xtrain, Ytrain, Xtest, hiddenLayerSizes, trainFcn, maxEpochs, regularization)
if exist('fitnet', 'file') == 2
    net = fitnet(hiddenLayerSizes, char(trainFcn));
    net.divideFcn = 'dividetrain';
    net.trainParam.showWindow = false;
    net.trainParam.showCommandLine = false;
    net.trainParam.epochs = maxEpochs;
    net.performParam.regularization = regularization;

    net = train(net, Xtrain.', Ytrain.');
    Ypred = net(Xtest.').';
    return
end

persistent warnedNoFitnet
if isempty(warnedNoFitnet)
    warning(['fitnet from Deep Learning Toolbox was not found. ', ...
        'Using the built-in single-hidden-layer MLP fallback instead.']);
    warnedNoFitnet = true;
end

Ypred = localFitPredictMLPFallback(Xtrain, Ytrain, Xtest, hiddenLayerSizes, maxEpochs, regularization);
end


function Ypred = localFitPredictMLPFallback(Xtrain, Ytrain, Xtest, hiddenLayerSizes, maxEpochs, regularization)
% Small deterministic MLP fallback for systems without Deep Learning Toolbox.
% It intentionally mirrors the Python benchmark settings closely:
% one ReLU hidden layer, Adam optimizer, L2 alpha, and early stopping.
% Xtrain and Ytrain are already autoscaled by the caller.
Xtrain(~isfinite(Xtrain)) = 0;
Ytrain(~isfinite(Ytrain)) = 0;
Xtest(~isfinite(Xtest)) = 0;

hiddenSize = max(1, round(hiddenLayerSizes(1)));
nTrain = size(Xtrain, 1);
nInput = size(Xtrain, 2);
nOutput = size(Ytrain, 2);

rng(17, 'twister');
perm = randperm(nTrain);
nVal = max(1, round(0.10 * nTrain));
if nTrain - nVal < 3
    nVal = 0;
end
if nVal > 0
    valIdx = perm(1:nVal);
    fitIdx = perm(nVal+1:end);
else
    valIdx = [];
    fitIdx = 1:nTrain;
end

Xfit = Xtrain(fitIdx, :);
Yfit = Ytrain(fitIdx, :);
if nVal > 0
    Xval = Xtrain(valIdx, :);
    Yval = Ytrain(valIdx, :);
else
    Xval = Xfit;
    Yval = Yfit;
end
nFit = size(Xfit, 1);

limit1 = sqrt(6 / (nInput + hiddenSize));
limit2 = sqrt(6 / (hiddenSize + nOutput));
W1 = (2 * rand(nInput, hiddenSize) - 1) * limit1;
b1 = zeros(1, hiddenSize);
W2 = (2 * rand(hiddenSize, nOutput) - 1) * limit2;
b2 = zeros(1, nOutput);

learningRate = 0.001;
lambda = max(0, regularization);
beta1 = 0.9;
beta2 = 0.999;
epsAdam = 1e-8;

mW1 = zeros(size(W1)); vW1 = zeros(size(W1));
mb1 = zeros(size(b1)); vb1 = zeros(size(b1));
mW2 = zeros(size(W2)); vW2 = zeros(size(W2));
mb2 = zeros(size(b2)); vb2 = zeros(size(b2));

bestLoss = inf;
patience = 10;
staleEpochs = 0;
tol = 1e-4;
bestW1 = W1; bestb1 = b1; bestW2 = W2; bestb2 = b2;

for epoch = 1:maxEpochs
    Z1 = Xfit * W1 + b1;
    H = max(0, Z1);
    Yhat = H * W2 + b2;
    E = Yhat - Yfit;

    Hval = max(0, Xval * W1 + b1);
    Eval = Hval * W2 + b2 - Yval;
    valLoss = mean(Eval(:).^2);

    if valLoss < bestLoss - tol
        bestLoss = valLoss;
        bestW1 = W1; bestb1 = b1; bestW2 = W2; bestb2 = b2;
        staleEpochs = 0;
    else
        staleEpochs = staleEpochs + 1;
        if staleEpochs >= patience
            break
        end
    end

    dY = (2 / nFit) * E;
    gW2 = H.' * dY + (lambda / nFit) * W2;
    gb2 = sum(dY, 1);
    dH = dY * W2.';
    dZ1 = dH .* (Z1 > 0);
    gW1 = Xfit.' * dZ1 + (lambda / nFit) * W1;
    gb1 = sum(dZ1, 1);

    [W1, mW1, vW1] = localAdamUpdate(W1, gW1, mW1, vW1, epoch, learningRate, beta1, beta2, epsAdam);
    [b1, mb1, vb1] = localAdamUpdate(b1, gb1, mb1, vb1, epoch, learningRate, beta1, beta2, epsAdam);
    [W2, mW2, vW2] = localAdamUpdate(W2, gW2, mW2, vW2, epoch, learningRate, beta1, beta2, epsAdam);
    [b2, mb2, vb2] = localAdamUpdate(b2, gb2, mb2, vb2, epoch, learningRate, beta1, beta2, epsAdam);
end

Htest = max(0, Xtest * bestW1 + bestb1);
Ypred = Htest * bestW2 + bestb2;
end


function [param, m, v] = localAdamUpdate(param, grad, m, v, t, lr, beta1, beta2, epsAdam)
m = beta1 * m + (1 - beta1) * grad;
v = beta2 * v + (1 - beta2) * (grad .^ 2);
mHat = m ./ (1 - beta1^t);
vHat = v ./ (1 - beta2^t);
param = param - lr * mHat ./ (sqrt(vHat) + epsAdam);
end


function [rmseVec, rVec] = evalMetrics(Ypred, Ytrue)
rmseVec = nan(size(Ypred, 1), 1);
rVec = nan(size(Ypred, 1), 1);
for ii = 1:size(Ypred, 1)
    yp = Ypred(ii, :).';
    yt = Ytrue(ii, :).';
    keep = isfinite(yp) & isfinite(yt);
    if ~any(keep)
        continue
    end
    err = yp(keep) - yt(keep);
    rmseVec(ii) = sqrt(mean(err.^2));
    if nnz(keep) >= 3 && std(yp(keep)) > 0 && std(yt(keep)) > 0
        rVec(ii) = corr(yp(keep), yt(keep), 'Rows', 'complete');
    end
end
end


function maxDiff = localMaxProcessSpectrumDiff(Pexpected, Psaved)
maxDiff = 0;
for ii = 1:numel(Pexpected.anitaspec)
    expected = Pexpected.anitaspec{ii};
    saved = Psaved.anitaspec{ii};
    delta = abs(expected(:) - saved(:));
    delta = delta(isfinite(delta));
    if ~isempty(delta)
        maxDiff = max(maxDiff, max(delta));
    end
end
end
