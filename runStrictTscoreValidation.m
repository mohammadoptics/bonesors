function result = runStrictTscoreValidation(userSettings)
%RUNSTRICTTSCOREVALIDATION Strict end-to-end validation for reconstructed spectra.
%
% This validation rebuilds the predicted spectra inside each outer
% leave-one-cadaver-out T-score fold. The held-out cadaver is excluded from:
%   1) reconstruction-model training,
%   2) predicted-spectrum generation for T-score training cadavers,
%   3) predictor standardization,
%   4) T-score model fitting and rank selection.
%
% The output figure matches the existing measured-vs-predicted T-score
% figure style, but the predicted-spectrum panel uses this stricter
% end-to-end validation.

%% ========================= USER SETTINGS =========================
pairedCadaversFile = "";
workbookFile = "";
outputFolder = "";

categoriesToUse = {'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};

% Reconstruction settings. Defaults match the Ratio_n_8 PLS reconstruction
% used for the strongest Raman-ratio discrimination.
reconTagsToUse = {'D2P1_MM00','D3P1_MM00'};
intactSpectraToUse = [2 3];
combineMode = "diff";
reconNormalizationRegion = "CH2";
reconNormalizationMethod = "peak";
normalizePredictors = true;
normalizeResponse = true;
exposedSpectrumToPredict = 2;
reconNComponents = 5;
standardizeBeforeReconstructionPLS = true;

% T-score analysis settings.
analysisTag = "D3P1_MM00";
analysisSpectrumNumber = 2;             % 1 = 0-mm, 2 = 3-mm, 3 = 6-mm
analysisSpectrumCombineMode = "concat"; % "concat" | "mean" | "diff" | "meanDiff"
tscoreNormalizationRegion = "CH2";       % "none" | "PO4" | "CO3" | "CH2" | "AmideI" | "AmideIII" | "FullSpectrum"
tscoreNormalizationMethod = "peak";
standardizeTscorePredictors = true;
tscoreModel = "SVR";                     % "PLS" | "SVR"
maxTscoreRank = 15;
fixedTscoreRank = [];                    % [] = choose rank by inner LOCO within each outer training set
svrBoxConstraint = 0.75;
svrEpsilon = 0.01;
svrKernelScale = 30;

% Optional measured-exposed T-score settings. These let the E reference
% panel use a different model/settings from the strict P panel.
measuredAnalysisSpectrumNumber = analysisSpectrumNumber;
measuredAnalysisSpectrumCombineMode = analysisSpectrumCombineMode;
measuredTscoreNormalizationRegion = tscoreNormalizationRegion;
measuredTscoreNormalizationMethod = tscoreNormalizationMethod;
measuredStandardizeTscorePredictors = standardizeTscorePredictors;
measuredTscoreModel = "SVR";
measuredMaxTscoreRank = maxTscoreRank;
measuredFixedTscoreRank = [];
measuredSvrBoxConstraint = 12.5;
measuredSvrEpsilon = 0.3;
measuredSvrKernelScale = 112.5;

% Native MATLAB implementation of the saved Python numerical conventions.
numerics = struct('plsAlgorithm',"NIPALS",'plsMaxIterations',1000, ...
    'plsTolerance',1e-6,'scalingDDOF',0,'svrKernelConvention',"python", ...
    'svrSolverTolerance',1e-6);

saveFigure = true;
makeFigures = true;
plotClassification = true;
saveStrictPredictedCadavers = true;
strictPredictedFileName = "strictPredictedCadavers.mat";
verbose = true;
%% ======================= END USER SETTINGS =======================

if nargin >= 1 && ~isempty(userSettings)
    pairedCadaversFile = localGetSetting(userSettings, 'pairedCadaversFile', pairedCadaversFile);
    workbookFile = localGetSetting(userSettings, 'workbookFile', workbookFile);
    outputFolder = localGetSetting(userSettings, 'outputFolder', outputFolder);
    categoriesToUse = localGetSetting(userSettings, 'categoriesToUse', categoriesToUse);

    reconTagsToUse = localGetSetting(userSettings, 'reconTagsToUse', reconTagsToUse);
    intactSpectraToUse = localGetSetting(userSettings, 'intactSpectraToUse', intactSpectraToUse);
    combineMode = localGetSetting(userSettings, 'combineMode', combineMode);
    reconNormalizationRegion = localGetSetting(userSettings, 'reconNormalizationRegion', reconNormalizationRegion);
    reconNormalizationMethod = localGetSetting(userSettings, 'reconNormalizationMethod', reconNormalizationMethod);
    normalizePredictors = localGetSetting(userSettings, 'normalizePredictors', normalizePredictors);
    normalizeResponse = localGetSetting(userSettings, 'normalizeResponse', normalizeResponse);
    exposedSpectrumToPredict = localGetSetting(userSettings, 'exposedSpectrumToPredict', exposedSpectrumToPredict);
    reconNComponents = localGetSetting(userSettings, 'reconNComponents', reconNComponents);
    standardizeBeforeReconstructionPLS = localGetSetting(userSettings, ...
        'standardizeBeforeReconstructionPLS', standardizeBeforeReconstructionPLS);

    analysisTag = localGetSetting(userSettings, 'analysisTag', analysisTag);
    analysisSpectrumNumber = localGetSetting(userSettings, 'analysisSpectrumNumber', analysisSpectrumNumber);
    analysisSpectrumCombineMode = localGetSetting(userSettings, 'analysisSpectrumCombineMode', analysisSpectrumCombineMode);
    tscoreNormalizationRegion = localGetSetting(userSettings, 'tscoreNormalizationRegion', tscoreNormalizationRegion);
    tscoreNormalizationMethod = localGetSetting(userSettings, 'tscoreNormalizationMethod', tscoreNormalizationMethod);
    standardizeTscorePredictors = localGetSetting(userSettings, 'standardizeTscorePredictors', standardizeTscorePredictors);
    tscoreModel = localGetSetting(userSettings, 'tscoreModel', tscoreModel);
    maxTscoreRank = localGetSetting(userSettings, 'maxTscoreRank', maxTscoreRank);
    fixedTscoreRank = localGetSetting(userSettings, 'fixedTscoreRank', fixedTscoreRank);
    svrBoxConstraint = localGetSetting(userSettings, 'svrBoxConstraint', svrBoxConstraint);
    svrEpsilon = localGetSetting(userSettings, 'svrEpsilon', svrEpsilon);
    svrKernelScale = localGetSetting(userSettings, 'svrKernelScale', svrKernelScale);

    measuredAnalysisSpectrumNumber = localGetSetting(userSettings, ...
        'measuredAnalysisSpectrumNumber', measuredAnalysisSpectrumNumber);
    measuredAnalysisSpectrumCombineMode = localGetSetting(userSettings, ...
        'measuredAnalysisSpectrumCombineMode', measuredAnalysisSpectrumCombineMode);
    measuredTscoreNormalizationRegion = localGetSetting(userSettings, ...
        'measuredTscoreNormalizationRegion', measuredTscoreNormalizationRegion);
    measuredTscoreNormalizationMethod = localGetSetting(userSettings, ...
        'measuredTscoreNormalizationMethod', measuredTscoreNormalizationMethod);
    measuredStandardizeTscorePredictors = localGetSetting(userSettings, ...
        'measuredStandardizeTscorePredictors', measuredStandardizeTscorePredictors);
    measuredTscoreModel = localGetSetting(userSettings, 'measuredTscoreModel', measuredTscoreModel);
    measuredMaxTscoreRank = localGetSetting(userSettings, 'measuredMaxTscoreRank', measuredMaxTscoreRank);
    measuredFixedTscoreRank = localGetSetting(userSettings, 'measuredFixedTscoreRank', measuredFixedTscoreRank);
    measuredSvrBoxConstraint = localGetSetting(userSettings, ...
        'measuredSvrBoxConstraint', measuredSvrBoxConstraint);
    measuredSvrEpsilon = localGetSetting(userSettings, 'measuredSvrEpsilon', measuredSvrEpsilon);
    measuredSvrKernelScale = localGetSetting(userSettings, ...
        'measuredSvrKernelScale', measuredSvrKernelScale);

    saveFigure = localGetSetting(userSettings, 'saveFigure', saveFigure);
    makeFigures = localGetSetting(userSettings, 'makeFigures', makeFigures);
    plotClassification = localGetSetting(userSettings, 'plotClassification', plotClassification);
    saveStrictPredictedCadavers = localGetSetting(userSettings, ...
        'saveStrictPredictedCadavers', saveStrictPredictedCadavers);
    strictPredictedFileName = localGetSetting(userSettings, ...
        'strictPredictedFileName', strictPredictedFileName);
    verbose = localGetSetting(userSettings, 'verbose', verbose);
    names = fieldnames(numerics);
    for k = 1:numel(names)
        numerics.(names{k}) = localGetSetting(userSettings,names{k},numerics.(names{k}));
    end
end

validateattributes(numerics.scalingDDOF,{'numeric'},{'scalar','integer','>=',0,'<=',1});
numerics.plsAlgorithm = string(validatestring(numerics.plsAlgorithm,{'NIPALS','SIMPLS'}));
numerics.svrKernelConvention = string(validatestring(numerics.svrKernelConvention,{'python','matlab'}));
validateattributes(numerics.plsMaxIterations,{'numeric'},{'scalar','positive','integer'});
validateattributes(numerics.plsTolerance,{'numeric'},{'scalar','positive','finite'});
validateattributes(numerics.svrSolverTolerance,{'numeric'},{'scalar','positive','finite'});
if ~all(ismember(analysisSpectrumNumber,exposedSpectrumToPredict))
    error('MainGUI:StrictTargets','P T-score columns must be included in the reconstruction targets.');
end

if ~isfile(pairedCadaversFile) || ~isfile(workbookFile) || strlength(outputFolder) == 0
    error('MainGUI:StrictInputPaths', ...
        'Supply pairedCadaversFile, workbookFile, and outputFolder in userSettings, or run from the GUI.');
end
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

[cads, pairedCadaversFile] = localLoadCads(pairedCadaversFile);
Tcat = readtable(workbookFile, 'VariableNamingRule','preserve');
labelMap = localBuildLabelMap(Tcat);

[validIdx, yAll, catsAll] = localValidCadavers(cads, labelMap, categoriesToUse, analysisTag);
if numel(validIdx) < 4
    error('Not enough valid cadavers for strict T-score validation.');
end

% Per-record normalization is independent of other donors. Cache it once;
% all learned standardization and model fitting remain fold-contained.
[numerics.preparedX,numerics.preparedY,numerics.preparedTags,numerics.preparedIDs] = ...
    localBuildReconstructionMatrices(cads,validIdx,intactSpectraToUse, ...
    exposedSpectrumToPredict,reconTagsToUse,combineMode,normalizePredictors, ...
    normalizeResponse,reconNormalizationRegion,reconNormalizationMethod);

if verbose
    fprintf('\n=== strict end-to-end T-score validation ===================\n');
    fprintf('Paired file: %s\n', pairedCadaversFile);
    fprintf('Cadavers used: %d\n', numel(validIdx));
    fprintf('Reconstruction tags: %s\n', strjoin(string(reconTagsToUse), ', '));
    fprintf('Analysis tag: %s   analysis spectrum: %s (%s) combine=%s\n', ...
        analysisTag, mat2str(analysisSpectrumNumber), ...
        localSpectrumDepthLabel(analysisSpectrumNumber), analysisSpectrumCombineMode);
    fprintf('Reconstruction: intact=%s combine=%s norm=%s/%s ncomp=%d\n', ...
        mat2str(intactSpectraToUse), combineMode, reconNormalizationRegion, ...
        reconNormalizationMethod, reconNComponents);
    fprintf('Measured E T-score: spectrum=%s (%s) combine=%s norm=%s/%s model=%s standardize=%d\n', ...
        mat2str(measuredAnalysisSpectrumNumber), localSpectrumDepthLabel(measuredAnalysisSpectrumNumber), ...
        measuredAnalysisSpectrumCombineMode, measuredTscoreNormalizationRegion, ...
        measuredTscoreNormalizationMethod, measuredTscoreModel, measuredStandardizeTscorePredictors);
    if strcmpi(measuredTscoreModel, "PLS")
        fprintf('Measured E PLS settings: maxRank=%d fixedRank=%s\n', ...
            measuredMaxTscoreRank, localRankText(measuredFixedTscoreRank));
    else
        fprintf('Measured E SVR settings: BoxConstraint=%.4g epsilon=%.4g kernelScale=%s\n', ...
            measuredSvrBoxConstraint, measuredSvrEpsilon, localValueText(measuredSvrKernelScale));
    end
    fprintf('Strict P T-score: spectrum=%s (%s) combine=%s norm=%s/%s model=%s standardize=%d\n', ...
        mat2str(analysisSpectrumNumber), localSpectrumDepthLabel(analysisSpectrumNumber), ...
        analysisSpectrumCombineMode, tscoreNormalizationRegion, ...
        tscoreNormalizationMethod, tscoreModel, standardizeTscorePredictors);
    if strcmpi(tscoreModel, "PLS")
        fprintf('Strict P PLS settings: maxRank=%d fixedRank=%s\n', ...
            maxTscoreRank, localRankText(fixedTscoreRank));
    else
        fprintf('Strict P SVR settings: BoxConstraint=%.4g epsilon=%.4g kernelScale=%s\n', ...
            svrBoxConstraint, svrEpsilon, localValueText(svrKernelScale));
    end
    fprintf('=============================================================\n\n');
end

% Panel A: measured exposed bone T-score prediction, with the same strict
% train-only rank-selection/standardization logic.
XE = localMeasuredFeatureMatrix(cads, validIdx, analysisTag, measuredAnalysisSpectrumNumber, ...
    measuredTscoreNormalizationRegion, measuredTscoreNormalizationMethod, ...
    measuredAnalysisSpectrumCombineMode);
[yPredE, rankE] = localStrictTscoreLOCO(XE, yAll, string({cads(validIdx).id}).', ...
    measuredMaxTscoreRank, measuredFixedTscoreRank, measuredStandardizeTscorePredictors, ...
    measuredTscoreModel, measuredSvrBoxConstraint, measuredSvrEpsilon, measuredSvrKernelScale,numerics);

% Panel B: predicted spectra. In each outer fold, all predicted features
% are generated without using the outer held-out cadaver.
yPredP = nan(size(yAll));
rankP = nan(size(yAll));
cadIDs = string({cads(validIdx).id}).';

for ii = 1:numel(validIdx)
    heldOutIdx = validIdx(ii);
    heldOutID = string(cads(heldOutIdx).id);
    trainCadIdx = validIdx(validIdx ~= heldOutIdx);

    XtrainP = [];
    yTrain = nan(numel(trainCadIdx), 1);
    trainIDs = strings(numel(trainCadIdx), 1);

    for jj = 1:numel(trainCadIdx)
        thisTrainIdx = trainCadIdx(jj);
        reconTrainIdx = trainCadIdx(trainCadIdx ~= thisTrainIdx);
        predCells = localPredictCadaverSpectra(cads, reconTrainIdx, thisTrainIdx, ...
            reconTagsToUse, intactSpectraToUse, exposedSpectrumToPredict, combineMode, ...
            normalizePredictors, normalizeResponse, reconNormalizationRegion, ...
            reconNormalizationMethod, reconNComponents, standardizeBeforeReconstructionPLS,numerics);

        thisFeature = localFeatureFromPredictedCells(cads(thisTrainIdx), predCells, ...
            analysisTag, analysisSpectrumNumber, tscoreNormalizationRegion, ...
            tscoreNormalizationMethod, analysisSpectrumCombineMode);
        if isempty(XtrainP)
            XtrainP = nan(numel(trainCadIdx), numel(thisFeature));
        end
        XtrainP(jj,:) = thisFeature;
        localLabels = localLabelsForCadaver(labelMap, cads(thisTrainIdx).id);
        yTrain(jj) = localLabels.Tscore;
        trainIDs(jj) = string(cads(thisTrainIdx).id);
    end

    predCellsTest = localPredictCadaverSpectra(cads, trainCadIdx, heldOutIdx, ...
        reconTagsToUse, intactSpectraToUse, exposedSpectrumToPredict, combineMode, ...
        normalizePredictors, normalizeResponse, reconNormalizationRegion, ...
        reconNormalizationMethod, reconNComponents, standardizeBeforeReconstructionPLS,numerics);
    XtestP = localFeatureFromPredictedCells(cads(heldOutIdx), predCellsTest, ...
        analysisTag, analysisSpectrumNumber, tscoreNormalizationRegion, ...
        tscoreNormalizationMethod, analysisSpectrumCombineMode);

    keepTrain = all(isfinite(XtrainP),2) & isfinite(yTrain);
    if ~all(keepTrain)
        XtrainP = XtrainP(keepTrain,:);
        yTrain = yTrain(keepTrain);
        trainIDs = trainIDs(keepTrain);
    end

    [yPredP(ii), rankP(ii)] = localFitPredictTscoreOneFold(XtrainP, yTrain, ...
        XtestP, trainIDs, maxTscoreRank, fixedTscoreRank, standardizeTscorePredictors, ...
        tscoreModel, svrBoxConstraint, svrEpsilon, svrKernelScale,numerics);

    if verbose
        fprintf(' Strict fold %-12s : P model = %-3s   predicted T-score = %.3f   measured = %.3f\n', ...
            heldOutID, tscoreModel, yPredP(ii), yAll(ii));
    end
end

result = struct();
result.cadIDs = cadIDs;
result.categories = catsAll;
result.yTrue = yAll;
result.yPredMeasured = yPredE;
result.yPredPredicted = yPredP;
result.rankMeasured = rankE;
result.rankPredicted = rankP;
result.settings = struct( ...
    'pairedCadaversFile', pairedCadaversFile, ...
    'workbookFile', workbookFile, ...
    'analysisTag', analysisTag, ...
    'analysisSpectrumNumber', analysisSpectrumNumber, ...
    'analysisSpectrumCombineMode', analysisSpectrumCombineMode, ...
    'reconTagsToUse', {reconTagsToUse}, ...
    'intactSpectraToUse', intactSpectraToUse, ...
    'combineMode', combineMode, ...
    'reconNormalizationRegion', reconNormalizationRegion, ...
    'reconNormalizationMethod', reconNormalizationMethod, ...
    'reconNComponents', reconNComponents, ...
    'measuredAnalysisSpectrumNumber', measuredAnalysisSpectrumNumber, ...
    'measuredAnalysisSpectrumCombineMode', measuredAnalysisSpectrumCombineMode, ...
    'measuredTscoreNormalizationRegion', measuredTscoreNormalizationRegion, ...
    'measuredTscoreNormalizationMethod', measuredTscoreNormalizationMethod, ...
    'measuredTscoreModel', measuredTscoreModel, ...
    'measuredMaxTscoreRank', measuredMaxTscoreRank, ...
    'measuredFixedTscoreRank', measuredFixedTscoreRank, ...
    'measuredStandardizeTscorePredictors', measuredStandardizeTscorePredictors, ...
    'measuredSvrBoxConstraint', measuredSvrBoxConstraint, ...
    'measuredSvrEpsilon', measuredSvrEpsilon, ...
    'measuredSvrKernelScale', measuredSvrKernelScale, ...
    'tscoreNormalizationRegion', tscoreNormalizationRegion, ...
    'tscoreNormalizationMethod', tscoreNormalizationMethod, ...
    'tscoreModel', tscoreModel, ...
    'maxTscoreRank', maxTscoreRank, ...
    'fixedTscoreRank', fixedTscoreRank, ...
    'standardizeTscorePredictors', standardizeTscorePredictors, ...
    'svrBoxConstraint', svrBoxConstraint, ...
    'svrEpsilon', svrEpsilon, ...
    'svrKernelScale', svrKernelScale, ...
    'makeFigures', makeFigures, ...
    'plotClassification', plotClassification, ...
    'saveStrictPredictedCadavers', saveStrictPredictedCadavers, ...
    'strictPredictedFileName', strictPredictedFileName);
for name = ["plsAlgorithm","plsMaxIterations","plsTolerance","scalingDDOF","svrKernelConvention","svrSolverTolerance"]
    result.settings.(name) = numerics.(name);
end
result.settings.normalizePredictors = normalizePredictors;
result.settings.normalizeResponse = normalizeResponse;
result.settings.standardizeBeforeReconstructionPLS = standardizeBeforeReconstructionPLS;
result.foldTrainingIDs = arrayfun(@(i)cadIDs((1:numel(cadIDs))~=i), ...
    (1:numel(cadIDs)).','UniformOutput',false);
result.trainingReconstructionRule = "For each outer training donor, exclude both that donor and the outer test donor.";

if verbose
    localPrintSummary(yAll, yPredE, yPredP, rankE, rankP, measuredTscoreModel, tscoreModel);
end
localSaveTables(outputFolder, result);
if makeFigures
    localPlotStrictTscore(yAll, yPredE, yPredP, catsAll, rankE, rankP, ...
        measuredAnalysisSpectrumNumber, analysisSpectrumNumber, measuredTscoreModel, ...
        tscoreModel, saveFigure, outputFolder);
    if plotClassification
        localPlotStrictClassification(yAll, yPredE, yPredP, catsAll, ...
            measuredTscoreModel, tscoreModel, saveFigure, outputFolder);
    end
end

if saveStrictPredictedCadavers
    strictPredictedFile = localSaveStrictPredictedCadavers(cads, validIdx, ...
        labelMap, outputFolder, strictPredictedFileName, reconTagsToUse, ...
        intactSpectraToUse, exposedSpectrumToPredict, combineMode, ...
        normalizePredictors, normalizeResponse, reconNormalizationRegion, ...
        reconNormalizationMethod, reconNComponents, standardizeBeforeReconstructionPLS,numerics);
    result.strictPredictedCadaversFile = strictPredictedFile;
    save(fullfile(outputFolder, 'strict_tscore_validation_result.mat'), 'result');
end

if verbose
    fprintf('Saved strict validation outputs in: %s\n', outputFolder);
    fprintf('=============================================================\n');
end
end


function [cads, pairedCadaversFile] = localLoadCads(pairedCadaversFile)
if strlength(string(pairedCadaversFile)) == 0
    [fn, fp] = uigetfile('*.mat', 'Select paired cadaver file');
    if isequal(fn,0)
        error('No paired cadaver file was selected.');
    end
    pairedCadaversFile = fullfile(fp, fn);
end
S = load(pairedCadaversFile);
if isfield(S, 'cads')
    cads = S.cads;
elseif isfield(S, 'cadavers')
    cads = S.cadavers;
elseif isfield(S, 'pairedCadavers')
    cads = S.pairedCadavers;
else
    error('The selected MAT file does not contain cads, cadavers, or pairedCadavers.');
end
cads = cads(:);
end


function labelMap = localBuildLabelMap(Tcat)
idCol = localFindColumn(Tcat, ["AGR-ID","AGR ID","Cadaver ID","CadaverID"]);
tCol = localFindColumn(Tcat, ["Distal Radius T-Score (1/3)", ...
    "Distal Radius T Score (1/3)", "T-score", "Tscore"]);
catCol = localFindColumn(Tcat, ["WHO Classification (Distal Radius; 1/3)", ...
    "WHO Classification (Distal Radius; MID)", "WHO Classification", "WHO"]);

labelMap = containers.Map('KeyType','char','ValueType','any');
for r = 1:height(Tcat)
    id = upper(strtrim(string(Tcat.(idCol)(r))));
    if strlength(id) == 0 || ismissing(id)
        continue
    end
    info = struct();
    info.Tscore = double(Tcat.(tCol)(r));
    info.Category = upper(strtrim(string(Tcat.(catCol)(r))));
    labelMap(char(id)) = info;
end
end


function col = localFindColumn(T, candidates)
names = string(T.Properties.VariableNames);
for c = 1:numel(candidates)
    hit = find(strcmpi(names, candidates(c)), 1);
    if ~isempty(hit)
        col = names(hit);
        return
    end
end
for c = 1:numel(candidates)
    hit = find(contains(lower(names), lower(candidates(c))), 1);
    if ~isempty(hit)
        col = names(hit);
        return
    end
end
error('Could not find required workbook column. Tried: %s', strjoin(candidates, ', '));
end


function [validIdx, y, cats] = localValidCadavers(cads, labelMap, categoriesToUse, analysisTag)
validIdx = [];
y = [];
cats = strings(0,1);
categoriesToUse = upper(string(categoriesToUse));
for i = 1:numel(cads)
    id = upper(string(cads(i).id));
    if startsWith(id, "IV") || ~isKey(labelMap, char(id))
        continue
    end
    info = labelMap(char(id));
    if ~isfinite(info.Tscore)
        continue
    end
    if ~isempty(categoriesToUse) && ~any(strcmpi(info.Category, categoriesToUse))
        continue
    end
    row = localFindTagRow(localListRows(cads(i).list), analysisTag, 1);
    if isempty(row)
        continue
    end
    validIdx(end+1,1) = i; %#ok<AGROW>
    y(end+1,1) = info.Tscore; %#ok<AGROW>
    cats(end+1,1) = info.Category; %#ok<AGROW>
end
end


function info = localLabelsForCadaver(labelMap, cadID)
id = upper(string(cadID));
if ~isKey(labelMap, char(id))
    error('No workbook labels were found for cadaver %s.', id);
end
info = labelMap(char(id));
end


function X = localMeasuredFeatureMatrix(cads, validIdx, analysisTag, spectrumNumber, normRegion, normMethod, combineMode)
X = [];
for ii = 1:numel(validIdx)
    c = validIdx(ii);
    listRows = localListRows(cads(c).list);
    row = localFindTagRow(listRows, analysisTag, 1);
    E = localAsCell(cads(c).E);
    if isempty(row) || row > numel(E) || isempty(E{row})
        continue
    end
    spec = E{row}(:, spectrumNumber);
    X(ii,:) = localSpectrumFeature(cads(c).wn(:), spec, normRegion, normMethod, combineMode); %#ok<AGROW>
end
end


function predCells = localPredictCadaverSpectra(cads, trainCadIdx, testCadIdx, tagsToUse, ...
    intactSpectraToUse, exposedSpectrumToPredict, combineMode, normalizePredictors, ...
    normalizeResponse, normRegion, normMethod, nComponents, standardizeBeforePLS,numerics)

trainRows = ismember(numerics.preparedIDs,trainCadIdx);
testRows = ismember(numerics.preparedIDs,testCadIdx);
assert(~any(trainRows & testRows),'MainGUI:StrictLeakage','Reconstruction train/test donors overlap.');
Xtrain = numerics.preparedX(trainRows,:); Ytrain = numerics.preparedY(trainRows,:);
Xtest = numerics.preparedX(testRows,:); testTags = numerics.preparedTags(testRows);

if isempty(Xtrain) || isempty(Xtest)
    error('Empty reconstruction train/test matrix for cadaver %s.', string(cads(testCadIdx).id));
end

nComp = min([nComponents, size(Xtrain,1)-1, size(Xtrain,2), size(Ytrain,2)]);
if nComp < 1
    error('Not enough reconstruction rows/components for cadaver %s.', string(cads(testCadIdx).id));
end

if standardizeBeforePLS
    [XtrainPLS, XtestPLS, ~, ~] = localAutoscaleTrainTest(Xtrain, Xtest,numerics.scalingDDOF);
    [YtrainPLS, ~, yMu, ySigma] = localAutoscaleTrainTest(Ytrain, Ytrain(1,:),numerics.scalingDDOF);
    YpredScaled = fitReconstructionPLS(XtrainPLS,YtrainPLS,XtestPLS,nComp, ...
        numerics.plsAlgorithm,numerics.plsMaxIterations,numerics.plsTolerance);
    Ypred = YpredScaled .* ySigma + yMu;
else
    Ypred = fitReconstructionPLS(Xtrain,Ytrain,Xtest,nComp, ...
        numerics.plsAlgorithm,numerics.plsMaxIterations,numerics.plsTolerance);
end

wnLen = numel(cads(testCadIdx).wn);
predCells = struct('Tag', cell(numel(testTags),1), 'Spectrum', cell(numel(testTags),1));
for r = 1:numel(testTags)
    compact = reshape(Ypred(r,:), wnLen, numel(exposedSpectrumToPredict));
    fullPred = nan(wnLen, max(exposedSpectrumToPredict));
    fullPred(:, exposedSpectrumToPredict) = compact;
    predCells(r).Tag = string(testTags(r));
    predCells(r).Spectrum = fullPred;
end
end


function strictPredictedFile = localSaveStrictPredictedCadavers(cads, validIdx, labelMap, ...
    outputFolder, fileName, tagsToUse, intactSpectraToUse, exposedSpectrumToPredict, ...
    combineMode, normalizePredictors, normalizeResponse, normRegion, normMethod, ...
    nComponents, standardizeBeforePLS,numerics)

cadsOut = cads(validIdx);
for ii = 1:numel(validIdx)
    heldOutIdx = validIdx(ii);
    trainCadIdx = validIdx(validIdx ~= heldOutIdx);
    predCells = localPredictCadaverSpectra(cads, trainCadIdx, heldOutIdx, ...
        tagsToUse, intactSpectraToUse, exposedSpectrumToPredict, combineMode, ...
        normalizePredictors, normalizeResponse, normRegion, normMethod, ...
        nComponents, standardizeBeforePLS,numerics);

    E = localAsCell(cads(heldOutIdx).E);
    P = cell(size(E));
    listRows = localListRows(cads(heldOutIdx).list);
    listOut = localEnsurePredictedListColumn(listRows, numel(P));
    for pp = 1:numel(predCells)
        row = localFindTagRow(listRows, predCells(pp).Tag, 1);
        if ~isempty(row) && row <= numel(P)
            P{row} = predCells(pp).Spectrum;
            listOut{row,3} = char(predCells(pp).Tag);
        end
    end
    cadsOut(ii).P = P;
    cadsOut(ii).list = listOut;

    info = localLabelsForCadaver(labelMap, cads(heldOutIdx).id);
    if ~isfield(cadsOut, 'WHOClassification_DistalRadius_1_3_')
        cadsOut(ii).WHOClassification_DistalRadius_1_3_ = char(info.Category);
    elseif isempty(cadsOut(ii).WHOClassification_DistalRadius_1_3_)
        cadsOut(ii).WHOClassification_DistalRadius_1_3_ = char(info.Category);
    end
end

cads = cadsOut; %#ok<NASGU>
strictPredictedFile = fullfile(outputFolder, char(string(fileName)));
save(strictPredictedFile, 'cads', '-v7.3');
fprintf('Saved strict reconstructed cadaver file for ratio/average plots: %s\n', strictPredictedFile);
end


function listOut = localEnsurePredictedListColumn(listRows, nRows)
if isempty(listRows)
    listOut = cell(nRows, 3);
    return
end

listOut = listRows;
if isvector(listOut)
    listOut = listOut(:);
end
if size(listOut,1) < nRows
    listOut{nRows, max(3, size(listOut,2))} = [];
end
if size(listOut,2) < 3
    listOut(:,3) = {[]};
end
end


function [X, Y, tags, rowCadIdx] = localBuildReconstructionMatrices(cads, cadIdx, intactSpectraToUse, ...
    exposedSpectrumToPredict, tagsToUse, combineMode, normalizePredictors, ...
    normalizeResponse, normRegion, normMethod)
X = [];
Y = [];
tags = strings(0,1);
rowCadIdx = zeros(0,1);

for ii = 1:numel(cadIdx)
    c = cadIdx(ii);
    E = localAsCell(cads(c).E);
    T = localAsCell(cads(c).T);
    listRows = localListRows(cads(c).list);
    nRows = min(numel(E), numel(T));

    for s = 1:nRows
        if isempty(E{s}) || isempty(T{s})
            continue
        end
        if size(E{s},2) < max(exposedSpectrumToPredict) || size(T{s},2) < max(intactSpectraToUse)
            continue
        end
        tag = localTagFromName(listRows{s,1});
        if ~localKeepTag(tag, tagsToUse)
            continue
        end

        wn = double(cads(c).wn(:));
        Twork = localMaybeNormalize(wn, T{s}, normalizePredictors, normRegion, normMethod);
        Ework = localMaybeNormalize(wn, E{s}, normalizeResponse, normRegion, normMethod);

        X(end+1,:) = localBuildPredictorRow(Twork, intactSpectraToUse, combineMode); %#ok<AGROW>
        Y(end+1,:) = localBuildResponseRow(Ework, exposedSpectrumToPredict); %#ok<AGROW>
        tags(end+1,1) = tag; %#ok<AGROW>
        rowCadIdx(end+1,1) = c; %#ok<AGROW>
    end
end
end


function Xrow = localFeatureFromPredictedCells(cad, predCells, analysisTag, spectrumNumber, normRegion, normMethod, combineMode)
tagList = string({predCells.Tag});
row = find(strcmpi(tagList, analysisTag), 1);
if isempty(row) || size(predCells(row).Spectrum,2) < max(spectrumNumber)
    Xrow = nan(1, numel(cad.wn) * localFeatureWidthMultiplier(spectrumNumber, combineMode));
    return
end
spec = predCells(row).Spectrum(:, spectrumNumber);
Xrow = localSpectrumFeature(cad.wn(:), spec, normRegion, normMethod, combineMode);
end


function feature = localSpectrumFeature(wn, spec, normRegion, normMethod, combineMode)
spec = double(spec);
if strcmpi(string(normRegion), "none")
    specNorm = spec;
else
    [specNorm,~,~,~,~,~] = normalizeSpectra(double(wn(:)), spec, ...
        char(normRegion), char(normMethod));
end
feature = localBuildAnalysisFeatureRow(specNorm, combineMode);
end


function feature = localBuildAnalysisFeatureRow(specMat, combineMode)
if size(specMat,2) == 1
    feature = specMat(:).';
    return
end

switch string(combineMode)
    case "concat"
        feature = reshape(specMat, 1, []);
    case "mean"
        feature = mean(specMat, 2, 'omitnan').';
    case "diff"
        if size(specMat,2) ~= 2
            error('analysisSpectrumCombineMode = "diff" requires exactly two spectra.');
        end
        feature = (specMat(:,2) - specMat(:,1)).';
    case "meanDiff"
        if size(specMat,2) ~= 2
            error('analysisSpectrumCombineMode = "meanDiff" requires exactly two spectra.');
        end
        feature = [mean(specMat, 2, 'omitnan').' (specMat(:,2) - specMat(:,1)).'];
    otherwise
        error('Unsupported analysis spectrum combine mode: %s', combineMode);
end
end


function mult = localFeatureWidthMultiplier(spectrumNumber, combineMode)
if numel(spectrumNumber) == 1
    mult = 1;
    return
end
switch string(combineMode)
    case "concat"
        mult = numel(spectrumNumber);
    case {"mean","diff"}
        mult = 1;
    case "meanDiff"
        mult = 2;
    otherwise
        mult = numel(spectrumNumber);
end
end


function [yPred, ranks] = localStrictTscoreLOCO(X, y, cadIDs, maxRank, fixedRank, standardizePredictors, ...
    tscoreModel, svrBoxConstraint, svrEpsilon, svrKernelScale,numerics)
yPred = nan(size(y));
ranks = nan(size(y));
for i = 1:numel(y)
    test = cadIDs == cadIDs(i);
    train = ~test;
    [yPred(i), ranks(i)] = localFitPredictTscoreOneFold(X(train,:), y(train), ...
        X(test,:), cadIDs(train), maxRank, fixedRank, standardizePredictors, ...
        tscoreModel, svrBoxConstraint, svrEpsilon, svrKernelScale,numerics);
end
end


function [yPred, rank] = localFitPredictTscoreOneFold(Xtrain, ytrain, Xtest, trainIDs, maxRank, fixedRank, standardizePredictors, ...
    tscoreModel, svrBoxConstraint, svrEpsilon, svrKernelScale,numerics)
keep = all(isfinite(Xtrain),2) & isfinite(ytrain);
Xtrain = Xtrain(keep,:);
ytrain = ytrain(keep);
trainIDs = trainIDs(keep);
if isempty(Xtrain) || isempty(Xtest) || any(~isfinite(Xtest))
    yPred = NaN;
    rank = NaN;
    return
end

if standardizePredictors
    [XtrainUse, XtestUse] = localAutoscaleTrainTest(Xtrain, Xtest,numerics.scalingDDOF);
else
    XtrainUse = Xtrain;
    XtestUse = Xtest;
end

if strcmpi(tscoreModel, "SVR")
    % MATLAB gaussian uses exp(-d^2/s^2); sklearn uses exp(-d^2/(2*s^2)).
    effectiveScale = svrKernelScale;
    if numerics.svrKernelConvention == "python", effectiveScale = sqrt(2)*effectiveScale; end
    mdl = fitrsvm(XtrainUse, ytrain, ...
        'KernelFunction','gaussian', ...
        'BoxConstraint', svrBoxConstraint, ...
        'Epsilon', svrEpsilon, ...
        'KernelScale', effectiveScale, 'Standardize', false, ...
        'Solver','SMO','KKTTolerance',numerics.svrSolverTolerance, ...
        'GapTolerance',numerics.svrSolverTolerance);
    yPred = predict(mdl, XtestUse);
    rank = NaN;
    return
end

maxRank = min([maxRank, size(Xtrain,1)-1, size(Xtrain,2)]);
if maxRank < 1
    yPred = NaN;
    rank = NaN;
    return
end

if isempty(fixedRank)
    rank = localChooseRankInnerLOCO(Xtrain, ytrain, trainIDs, maxRank, standardizePredictors,numerics.scalingDDOF);
else
    rank = min(max(1, round(fixedRank)), maxRank);
end

[~,~,~,~,beta] = plsregress(XtrainUse, ytrain, rank);
yPred = [ones(size(XtestUse,1),1) XtestUse] * beta;
end


function bestRank = localChooseRankInnerLOCO(X, y, cadIDs, maxRank, standardizePredictors,ddof)
uniqueIDs = unique(cadIDs, 'stable');
pred = nan(numel(y), maxRank);
for i = 1:numel(uniqueIDs)
    test = cadIDs == uniqueIDs(i);
    train = ~test;
    Xtrain = X(train,:);
    Xtest = X(test,:);
    if standardizePredictors
        [Xtrain, Xtest] = localAutoscaleTrainTest(Xtrain, Xtest,ddof);
    end
    foldMaxRank = min([maxRank, size(Xtrain,1)-1, size(Xtrain,2)]);
    for r = 1:foldMaxRank
        [~,~,~,~,beta] = plsregress(Xtrain, y(train), r);
        pred(test,r) = [ones(sum(test),1) Xtest] * beta;
    end
end
rmse = sqrt(mean((pred - y).^2, 1, 'omitnan'));
[~, bestRank] = min(rmse);
if isempty(bestRank) || ~isfinite(bestRank)
    bestRank = 1;
end
end


function Swork = localMaybeNormalize(wn, S, doNormalize, normRegion, normMethod)
if ~doNormalize || strcmpi(string(normRegion), "none")
    Swork = double(S);
else
    [Swork,~,~,~,~,~] = normalizeSpectra(double(wn), double(S), char(normRegion), char(normMethod));
end
end


function [XtrainZ, XtestZ, mu, sigma] = localAutoscaleTrainTest(Xtrain, Xtest,ddof)
mu = mean(Xtrain, 1, 'omitnan');
sigma = std(Xtrain, 1-ddof, 1, 'omitnan');
sigma(~isfinite(sigma) | sigma == 0) = 1;
XtrainZ = (Xtrain - mu) ./ sigma;
XtestZ = (Xtest - mu) ./ sigma;
end


function Xrow = localBuildPredictorRow(Tmat, intactSpectraToUse, combineMode)
selected = Tmat(:, intactSpectraToUse);
switch string(combineMode)
    case "concat"
        Xrow = reshape(selected, 1, []);
    case "mean"
        Xrow = mean(selected, 2, 'omitnan').';
    case "diff"
        if numel(intactSpectraToUse) == 1
            Xrow = selected.';
        elseif numel(intactSpectraToUse) == 2
            Xrow = (selected(:,2) - selected(:,1)).';
        else
            error('combineMode = "diff" requires one or two intact spectra.');
        end
    case "meanDiff"
        if numel(intactSpectraToUse) ~= 2
            error('combineMode = "meanDiff" requires exactly two intact spectra.');
        end
        Xrow = [mean(selected, 2, 'omitnan').' (selected(:,2) - selected(:,1)).'];
    otherwise
        error('Unsupported combine mode: %s', combineMode);
end
end


function Yrow = localBuildResponseRow(Emat, exposedSpectrumToPredict)
selected = Emat(:, exposedSpectrumToPredict);
Yrow = reshape(selected, 1, []);
end


function keep = localKeepTag(tag, tagsToUse)
if isempty(tagsToUse)
    keep = true;
else
    keep = any(strcmpi(string(tag), string(tagsToUse)));
end
end


function cellsOut = localAsCell(x)
if isempty(x)
    cellsOut = {};
elseif iscell(x)
    cellsOut = x(:);
else
    cellsOut = num2cell(x(:));
end
end


function rows = localListRows(listField)
if isempty(listField)
    rows = {};
elseif iscell(listField)
    rows = listField;
    if isvector(rows)
        rows = rows(:);
    end
else
    rows = cellstr(string(listField));
end
end


function rowIdx = localFindTagRow(listRows, wantedTag, listCol)
rowIdx = [];
if isempty(listRows) || size(listRows,2) < listCol
    return
end
wantedTag = regexprep(string(wantedTag), '_r\d+$', '');
for rr = 1:size(listRows,1)
    tag = localTagFromName(listRows{rr,listCol});
    if strcmpi(tag, wantedTag)
        rowIdx = rr;
        return
    end
end
end


function tag = localTagFromName(name)
name = string(name);
name = erase(name, ".mat");
parts = split(name, "_");
if numel(parts) >= 3
    tag = strjoin(parts(3:end), "_");
else
    tag = name;
end
tag = regexprep(tag, '_r\d+$', '');
end


function txt = localRankText(rankValue)
if isempty(rankValue)
    txt = "innerLOCO";
else
    txt = string(rankValue);
end
end


function localPrintSummary(y, yPredE, yPredP, rankE, rankP, measuredTscoreModel, predictedTscoreModel)
rE = corr(y, yPredE, 'Rows','complete');
rP = corr(y, yPredP, 'Rows','complete');
rmseE = sqrt(mean((yPredE - y).^2, 'omitnan'));
rmseP = sqrt(mean((yPredP - y).^2, 'omitnan'));
fprintf('\n=== strict validation summary ==============================\n');
if strcmpi(measuredTscoreModel, "PLS")
    fprintf('Measured exposed bone: r = %.3f   RMSE_CV = %.3f   model = PLS   median rank = %.1f\n', ...
        rE, rmseE, median(rankE, 'omitnan'));
else
    fprintf('Measured exposed bone: r = %.3f   RMSE_CV = %.3f   model = %s\n', ...
        rE, rmseE, char(string(measuredTscoreModel)));
end
if strcmpi(predictedTscoreModel, "PLS")
    fprintf('Strict ML-predicted  : r = %.3f   RMSE_CV = %.3f   model = PLS   median rank = %.1f\n', ...
        rP, rmseP, median(rankP, 'omitnan'));
else
    fprintf('Strict ML-predicted  : r = %.3f   RMSE_CV = %.3f   model = %s\n', ...
        rP, rmseP, char(string(predictedTscoreModel)));
end
fprintf('=============================================================\n\n');
end


function localSaveTables(outputFolder, result)
T = table(result.cadIDs, result.categories, result.yTrue, ...
    result.yPredMeasured, result.yPredPredicted, result.rankMeasured, result.rankPredicted, ...
    'VariableNames', {'CadaverID','Category','MeasuredTscore', ...
    'PredictedTscore_MeasuredExposed','PredictedTscore_StrictMLPredicted', ...
    'Rank_MeasuredExposed','Rank_StrictMLPredicted'});
writetable(T, fullfile(outputFolder, 'strict_tscore_predictions.csv'));

summary = table( ...
    ["Measured exposed"; "Strict ML-predicted"], ...
    [string(result.settings.measuredTscoreModel); string(result.settings.tscoreModel)], ...
    [corr(result.yTrue, result.yPredMeasured, 'Rows','complete'); ...
     corr(result.yTrue, result.yPredPredicted, 'Rows','complete')], ...
    [sqrt(mean((result.yPredMeasured - result.yTrue).^2, 'omitnan')); ...
     sqrt(mean((result.yPredPredicted - result.yTrue).^2, 'omitnan'))], ...
    [median(result.rankMeasured, 'omitnan'); median(result.rankPredicted, 'omitnan')], ...
    'VariableNames', {'DataSource','TscoreModel','r','RMSE_CV','MedianRank'});
writetable(summary, fullfile(outputFolder, 'strict_tscore_summary.csv'));
save(fullfile(outputFolder, 'strict_tscore_validation_result.mat'), 'result');
end


function localPlotStrictTscore(yTrue, yPredE, yPredP, cats, rankE, rankP, ...
    measuredSpectrumNumber, predictedSpectrumNumber, measuredTscoreModel, ...
    predictedTscoreModel, saveFigure, outputFolder)
figure('Name','Strict E and P T-score validation', ...
    'Color','w','Units','inches','Position',[0 0 15 7]);
tiledlayout(1,2,'TileSpacing','loose','Padding','compact');

localPlotPanel(nexttile, yTrue, yPredE, cats, rankE, ...
    sprintf('A (Measured exposed bone, %s)', localSpectrumDepthLabel(measuredSpectrumNumber)), ...
    measuredTscoreModel);
localPlotPanel(nexttile, yTrue, yPredP, cats, rankP, ...
    sprintf('B (Strict ML-predicted bone, %s)', localSpectrumDepthLabel(predictedSpectrumNumber)), ...
    predictedTscoreModel);

if saveFigure
    exportgraphics(gcf, fullfile(outputFolder, 'strict_tscore_E_vs_P.png'), 'Resolution', 300);
    savefig(gcf, fullfile(outputFolder, 'strict_tscore_E_vs_P.fig'));
end
end


function localPlotStrictClassification(yTrue, yPredE, yPredP, cats, measuredTscoreModel, ...
    predictedTscoreModel, saveFigure, outputFolder)
figure('Name','Strict E and P T-score classification', ...
    'Color','w','Units','inches','Position',[0 0 13 10]);
tl = tiledlayout(2,2,'TileSpacing','compact','Padding','compact');

ax1 = nexttile(tl);
localPlotConfusionPanel(ax1, yTrue, yPredE, cats, 'A (Measured exposed bone)');
ax2 = nexttile(tl);
localPlotRocPanel(ax2, yPredE, cats, 'B (Measured exposed bone)');
ax3 = nexttile(tl);
localPlotConfusionPanel(ax3, yTrue, yPredP, cats, 'C (Strict ML-predicted bone)');
ax4 = nexttile(tl);
localPlotRocPanel(ax4, yPredP, cats, 'D (Strict ML-predicted bone)');

metricsMeasured = localPrintClassificationSummary(yTrue, yPredE, cats, ...
    sprintf('Strict measured exposed bone %s', upper(string(measuredTscoreModel))));
metricsPredicted = localPrintClassificationSummary(yTrue, yPredP, cats, ...
    sprintf('Strict ML-predicted bone %s', upper(string(predictedTscoreModel))));
writetable(metricsMeasured, fullfile(outputFolder, 'strict_classification_metrics_measured.csv'));
writetable(metricsPredicted, fullfile(outputFolder, 'strict_classification_metrics_predicted.csv'));

if saveFigure
    exportgraphics(gcf, fullfile(outputFolder, 'strict_tscore_confusion_roc_E_vs_P.png'), 'Resolution', 300);
    savefig(gcf, fullfile(outputFolder, 'strict_tscore_confusion_roc_E_vs_P.fig'));
end
end


function metricsTable = localPrintClassificationSummary(yTrue, yPred, cats, tableTitle)
catList = {'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
trueCats = string(cats);
predCats = localTscoreToCategory(yPred);
[C, orderUsed] = confusionmat(trueCats, predCats, 'Order', string(catList));
metricsTable = localComputeMulticlassMetrics(C, orderUsed);

fprintf('\nConfusion matrix for %s:\n', tableTitle);
disp(array2table(C, 'VariableNames', cellstr(orderUsed), 'RowNames', cellstr(orderUsed)));

displayTable = table(metricsTable.Class, ...
    round(metricsTable.Precision, 2), ...
    round(metricsTable.Sensitivity, 2), ...
    round(metricsTable.Specificity, 2), ...
    round(metricsTable.Accuracy, 2), ...
    'VariableNames', {'WHO_Class','Precision','Sensitivity','Specificity','Accuracy'});
fprintf('\nTable. Summary of classification performance metrics - %s\n', tableTitle);
disp(displayTable);
end


function localPlotConfusionPanel(ax, yTrue, yPred, cats, panelTitle)
catList = {'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
catShort = {'N','OPE','OP'};
trueCats = string(cats);
predCats = localTscoreToCategory(yPred);
[C, ~] = confusionmat(trueCats, predCats, 'Order', string(catList));

hold(ax,'on');
nClass = size(C,1);
imagesc(ax, zeros(nClass));
colormap(ax, [1 1 1]);
caxis(ax, [0 1]);
axis(ax,'image');
set(ax,'XLim',[0.5 nClass+0.5], 'YLim',[0.5 nClass+0.5], 'YDir','reverse');

diagColor = [0.80 0.90 1.00];
for k = 1:nClass
    rectangle(ax, 'Position',[k-0.5, k-0.5, 1, 1], ...
        'FaceColor',diagColor, 'EdgeColor','none');
end

gridColor = [0.80 0.80 0.80];
for g = 0.5 : 1 : (nClass+0.5)
    line(ax, [0.5 nClass+0.5], [g g], 'Color',gridColor, 'LineWidth',2);
    line(ax, [g g], [0.5 nClass+0.5], 'Color',gridColor, 'LineWidth',2);
end
rectangle(ax, 'Position',[0.5 0.5 nClass nClass], ...
    'EdgeColor','k','LineWidth',4,'FaceColor','none');

for i = 1:nClass
    for j = 1:nClass
        text(ax, j, i, num2str(C(i,j)), ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','middle', ...
            'FontSize',24, ...
            'FontWeight','bold', ...
            'Color','k');
    end
end

set(ax,'XTick',1:nClass, ...
    'YTick',1:nClass, ...
    'XTickLabel',catShort, ...
    'YTickLabel',catShort, ...
    'FontSize',17, ...
    'LineWidth',3, ...
    'XAxisLocation','top', ...
    'TickLength',[0 0]);
xtickangle(ax, 0);
ytickangle(ax, 0);
xlabel(ax,'Predicted','FontSize',20);
ylabel(ax,'Actual','FontSize',20);
title(ax, panelTitle, 'Interpreter','none', 'FontSize',20, 'FontWeight','bold');
hold(ax,'off');
end


function localPlotRocPanel(ax, yPred, cats, panelTitle)
pairs = { ...
    'NORMAL', 'OSTEOPENIA', 'N vs OPE', 'b'; ...
    'NORMAL', 'OSTEOPOROSIS', 'N vs OP', 'r'; ...
    'OSTEOPENIA', 'OSTEOPOROSIS', 'OPE vs OP', 'g'};

hold(ax,'on');
plot(ax, [0 1], [0 1], 'k--', 'LineWidth',1.5, 'HandleVisibility','off');
trueCats = string(cats(:));

for p = 1:size(pairs, 1)
    positiveClass = string(pairs{p, 1});
    negativeClass = string(pairs{p, 2});
    keep = strcmpi(trueCats, positiveClass) | strcmpi(trueCats, negativeClass);
    labels = strcmpi(trueCats(keep), positiveClass);
    scores = yPred(keep);
    [fpr, tpr, aucVal] = localBinaryRoc(labels, scores);
    plot(ax, fpr, tpr, '-', ...
        'Color', pairs{p, 4}, ...
        'LineWidth',2.5, ...
        'DisplayName', sprintf('%s  AUC=%.2f', pairs{p, 3}, aucVal));
end

axis(ax,'square');
xlim(ax,[0 1]);
ylim(ax,[0 1]);
xlabel(ax,'False positive rate');
ylabel(ax,'True positive rate');
title(ax, panelTitle, 'Interpreter','none', 'FontSize',20, 'FontWeight','bold');
legend(ax, 'Location','southeast', 'Box','off', 'FontSize',14);
set(ax,'FontSize',17,'LineWidth',3,'Box','off');
hold(ax,'off');
end


function [fpr, tpr, aucVal] = localBinaryRoc(labels, scores)
labels = logical(labels(:));
scores = scores(:);
keep = isfinite(scores);
labels = labels(keep);
scores = scores(keep);

if numel(unique(labels)) < 2
    fpr = [0; 1];
    tpr = [0; 1];
    aucVal = NaN;
    return
end

[scoresSorted, ord] = sort(scores, 'descend');
labelsSorted = labels(ord);
P = sum(labelsSorted);
N = sum(~labelsSorted);
tprAll = [0; cumsum(labelsSorted) ./ max(P, eps)];
fprAll = [0; cumsum(~labelsSorted) ./ max(N, eps)];

scoreChange = [true; diff(scoresSorted) ~= 0];
keepPts = [scoreChange; true];
tpr = tprAll(keepPts);
fpr = fprAll(keepPts);
aucVal = trapz(fpr, tpr);
end


function predCats = localTscoreToCategory(yPred)
predCats = strings(size(yPred));
predCats(yPred >= -1) = "NORMAL";
predCats(yPred < -1 & yPred > -2.5) = "OSTEOPENIA";
predCats(yPred <= -2.5) = "OSTEOPOROSIS";
predCats(~isfinite(yPred)) = "UNKNOWN";
end


function metricsTable = localComputeMulticlassMetrics(C, orderUsed)
nClass = numel(orderUsed);
classNames = string(orderUsed(:));
TP = diag(C);
FP = sum(C,1).' - TP;
FN = sum(C,2) - TP;
TN = sum(C(:)) - TP - FP - FN;

precision = TP ./ max(TP + FP, eps);
sensitivity = TP ./ max(TP + FN, eps);
specificity = TN ./ max(TN + FP, eps);
f1 = 2 * precision .* sensitivity ./ max(precision + sensitivity, eps);
accuracy = (TP + TN) ./ max(TP + TN + FP + FN, eps);

metricsTable = table(classNames, TP, TN, FP, FN, precision, sensitivity, ...
    specificity, f1, accuracy, ...
    'VariableNames', {'Class','TP','TN','FP','FN','Precision','Sensitivity', ...
    'Specificity','F1score','Accuracy'});
end


function localPlotPanel(ax, yTrue, yPred, cats, ranks, titleText, tscoreModel)
catList = {'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
catClr = containers.Map(catList, {'b','g','r'});
marks = {'s','d','o'};
dotSize = 190;
hold(ax,'on');
axis(ax,'square');

hLegend = gobjects(numel(catList),1);
for k = 1:numel(catList)
    idx = strcmpi(cats, catList{k}) & isfinite(yPred);
    scatter(ax, yTrue(idx), yPred(idx), dotSize, ...
        'Marker', marks{k}, ...
        'MarkerFaceColor', catClr(catList{k}), ...
        'MarkerEdgeColor', catClr(catList{k}), ...
        'HandleVisibility','off');
    hLegend(k) = plot(ax, nan, nan, marks{k}, ...
        'MarkerFaceColor', catClr(catList{k}), ...
        'MarkerEdgeColor', catClr(catList{k}), ...
        'LineStyle','none', ...
        'MarkerSize', 10, ...
        'DisplayName', sprintf('%s (n=%d)', catList{k}, sum(idx)));
end

lims = [min([yTrue; yPred], [], 'omitnan') max([yTrue; yPred], [], 'omitnan')];
pad = 0.08 * range(lims);
if pad == 0 || ~isfinite(pad)
    pad = 1;
end
lims = lims + [-pad pad];
xlim(ax, lims);
ylim(ax, lims);
plot(ax, lims, lims, 'k--', 'LineWidth', 2.5, 'HandleVisibility','off');

rVal = corr(yTrue, yPred, 'Rows','complete');
rmseVal = sqrt(mean((yPred - yTrue).^2, 'omitnan'));
if strcmpi(tscoreModel, "PLS")
    modelText = sprintf('median rank = %.1f', median(ranks, 'omitnan'));
else
    modelText = sprintf('model = %s', char(upper(string(tscoreModel))));
end
text(ax, 0.06, 0.94, sprintf('r = %.3f\nRMSE_{CV} = %.3f\n%s\nn = %d', ...
    rVal, rmseVal, modelText, sum(isfinite(yPred))), ...
    'Units','normalized', 'VerticalAlignment','top', 'FontSize',18);

xlabel(ax,'DXA measured Wrist T-Score');
ylabel(ax,'Predicted Wrist T-score from Finger Raman');
title(ax, titleText, 'FontWeight','bold');
legend(ax, hLegend(isgraphics(hLegend)), 'Location','southeast', 'Box','off');
set(ax,'FontSize',18,'LineWidth',2.5,'Box','off');
end


function label = localSpectrumDepthLabel(spectrumNumber)
if numel(spectrumNumber) > 1
    if isequal(spectrumNumber(:).', [1 2])
        label = '0-mm and 3-mm offsets';
    else
        label = sprintf('spectra %s', mat2str(spectrumNumber));
    end
    return
end
switch spectrumNumber
    case 1
        label = '0-mm offset';
    case 2
        label = '3-mm offset';
    case 3
        label = '6-mm offset';
    otherwise
        label = sprintf('spectrum %d', spectrumNumber);
end
end


function value = localGetSetting(settings, fieldName, defaultValue)
if isfield(settings, fieldName) && ~isempty(settings.(fieldName))
    value = settings.(fieldName);
else
    value = defaultValue;
end
end


function txt = localValueText(value)
if isnumeric(value) && isscalar(value)
    txt = sprintf('%.4g', value);
else
    txt = char(string(value));
end
end
