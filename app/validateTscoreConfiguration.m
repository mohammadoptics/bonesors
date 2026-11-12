function config = validateTscoreConfiguration(config)
%VALIDATETSCORECONFIGURATION Validate and normalize dialog settings.

config = completeTscoreConfiguration(config);
config.figureMode=string(validatestring(char(config.figureMode),{'individual','locationComparison'}));
publication=config.figureMode=="locationComparison";
config.locationCombineMode=string(validatestring(char(config.locationCombineMode),{'records','concat','mean'}));
config.locationTags=upper(strtrim(string(config.locationTags(:).')));
needsLocations=config.locationCombineMode~="records";
if publication
    requested=tscoreFigurePlan(config,config.locationTags);
    needsLocations=any([requested.useRaman]);
end
if needsLocations
    if isempty(config.locationTags) || any(strlength(config.locationTags)==0) || ...
            numel(unique(config.locationTags))~=numel(config.locationTags) || ...
            any(cellfun(@isempty,regexp(cellstr(config.locationTags),'^D\d+P\d+_[A-Z]+\d+$','once')))
        error('MainGUI:TscoreLocations','Select unique exact location tags on Analysis, for example D2P1_MM00 and D3P1_MM00.');
    end
    if any(upper(string(config.models))=="CNN")
        error('MainGUI:TscoreLocations','Location fusion is not supported by CNN. Choose PLS, SVR, Ridge, or MLP.');
    end
end
config.predictorSource = string(validatestring(char(config.predictorSource), ...
    {'raman','demographics','combined'}));
config.models = unique(upper(string(config.models)), 'stable');
allowedModels = ["PLS" "SVR" "MLP" "CNN" "RIDGE"];
if isempty(config.models) || any(~ismember(config.models, allowedModels))
    error('MainGUI:TscoreModels', ...
        'Select at least one valid model: PLS, SVR, MLP, CNN, or RIDGE.');
end

usesDemographics = any(config.predictorSource == ["demographics" "combined"]);
if publication
    plan=tscoreFigurePlan(config,config.locationTags);
    if isempty(plan)
        error('MainGUI:TscorePublication','Select at least one available panel on the Figure tab. Locations are selected on Analysis.');
    end
    usesDemographics=any([plan.withDemographics]);
    if any(config.models=="CNN")
        error('MainGUI:TscorePublication','Multi-panel comparisons support PLS, SVR, Ridge and MLP, not CNN.');
    end
end
config.validationProtocol = string(validatestring(char(config.validationProtocol), ...
    {'legacy','matchedKFold'}));
matched = config.validationProtocol == "matchedKFold";
localPositiveScalar(config.matchedInnerFolds,'Matched inner folds');
if config.matchedInnerFolds<2 || config.matchedInnerFolds~=fix(config.matchedInnerFolds)
    error('MainGUI:TscoreNumericSetting','Matched inner folds must be an integer of at least 2.');
end
if config.blockScaleRamanDemographics
    blockModelOK = all(ismember(config.models,["PLS" "SVR" "RIDGE" "MLP"]));
    if (~publication && config.predictorSource ~= "combined") || ~blockModelOK || ~config.standardizePredictors
        error('MainGUI:TscoreBlockScaling', ...
            ['Block scaling requires combined predictors and within-fold standardization: ' ...
             'choose PLS, SVR, ridge, or MLP.']);
    end
end
if usesDemographics && ~any([config.useAge config.useSex config.useBMI config.useWeight])
    error('MainGUI:TscorePredictors', ...
        'Select at least one demographic predictor.');
end
if config.predictorSource ~= "raman" && any(config.models == "CNN")
    error('MainGUI:TscoreCNNPredictors', ...
        ['The current 1-D CNN accepts Raman spectra only. Select Raman only, ' ...
         'or deselect CNN for demographic or combined predictors.']);
end
if any(config.models == "CNN") && string(config.ramanFeatureMode) ~= "spectrum"
    error('MainGUI:TscoreCNNFeatures', ...
        'The 1-D CNN requires the full Raman spectrum feature mode.');
end

availability = tscoreModelAvailability();
for model = config.models
    if ~availability.(char(model))
        if model == "CNN"
            error('MainGUI:TscoreModelUnavailable', ...
                ['CNN is not available because MATLAB Deep Learning Toolbox ' ...
                 'is not installed. Choose PLS, SVR, or MLP.']);
        else
            error('MainGUI:TscoreModelUnavailable', ...
                '%s is not available in this MATLAB installation.', model);
        end
    end
end

config.ramanFeatureMode = string(validatestring(char(config.ramanFeatureMode), ...
    {'spectrum','ratios','ratiosConcat','ratiosMeanDiff','ratiosNormDiff'}));
config.ramanRatioNames = localValidateRatioNames(config.ramanRatioNames);
if any(config.ramanFeatureMode == ["ratios" "ratiosConcat" ...
        "ratiosMeanDiff" "ratiosNormDiff"]) && isempty(config.ramanRatioNames)
    error('MainGUI:TscoreRatios', ...
        'Select at least one Raman ratio for the chosen feature representation.');
end
config.normalizationRegion = string(validatestring(char(config.normalizationRegion), ...
    {'none','PO4','CO3','CH2','AmideI','AmideIII','FullSpectrum'}));
config.normalizationMethod = string(validatestring(char(config.normalizationMethod), ...
    {'peak','peakBaseline','area'}));
config.svrOptimizationMode = string(validatestring(char(config.svrOptimizationMode), ...
    {'bayesian','nested','fixed'}));

localPositiveScalar(config.maxPLSRank, 'Maximum PLS rank');
localPositiveVector(config.ridgeAlphaGrid, 'Ridge alpha grid');
if ~isvector(config.ridgeAlphaGrid)
    error('MainGUI:TscoreNumericSetting','Ridge alpha grid must be a vector.');
end
config.ridgeAlphaGrid = unique(config.ridgeAlphaGrid(:).','stable');
localPositiveScalar(config.ridgeInnerFolds, 'Ridge inner folds');
if config.ridgeInnerFolds < 2 || config.ridgeInnerFolds ~= fix(config.ridgeInnerFolds)
    error('MainGUI:TscoreNumericSetting','Ridge inner folds must be an integer of at least 2.');
end
if ~isempty(config.fixedPLSRank)
    localPositiveScalar(config.fixedPLSRank, 'Fixed PLS component count');
end
localPositiveScalar(config.svrBoxConstraint, 'SVR box constraint');
localNonnegativeScalar(config.svrEpsilon, 'SVR epsilon');
localPositiveScalar(config.svrKernelScale, 'SVR kernel scale');
localPositiveVector(config.svrBoxConstraintGrid, 'SVR box-constraint grid');
localNonnegativeVector(config.svrEpsilonGrid, 'SVR epsilon grid');
localPositiveVector(config.svrKernelScaleGrid, 'SVR kernel-scale grid');
localPositiveScalar(config.svrInnerFolds, 'SVR inner folds');
localPositiveScalar(config.svrMaxCandidates, 'SVR maximum candidates');
if matched && any(config.models == "SVR") && config.svrOptimizationMode ~= "nested"
    error('MainGUI:MatchedSVRMode','Matched K-fold SVR uses the complete nested grid.');
end
if ~matched && config.svrOptimizationMode == "bayesian" && any(config.models == "SVR")
    if exist('bayesopt','file') ~= 2
        error('MainGUI:TscoreBayesianUnavailable', ...
            'Bayesian SVR optimization requires MATLAB bayesopt.');
    end
    if config.svrMaxCandidates < 4
        error('MainGUI:TscoreBayesianEvaluations', ...
            'Bayesian SVR optimization requires at least 4 objective evaluations.');
    end
end
localPositiveScalar(config.mlpMaxEpochs, 'MLP epochs');
localNonnegativeScalar(config.mlpRegularization, 'MLP regularization');
localPositiveScalar(config.cnnMaxEpochs, 'CNN epochs');
localPositiveScalar(config.cnnMiniBatchSize, 'CNN mini-batch size');
localNonnegativeScalar(config.cnnRegularization, 'CNN regularization');
localNonnegativeScalar(config.randomSeed, 'Random seed');
if (matched || any(config.models == "RIDGE")) && (config.randomSeed > 2^32-1 || config.randomSeed ~= fix(config.randomSeed))
    error('MainGUI:TscoreNumericSetting','Random seed must be an integer from 0 to 2^32-1.');
end
if isempty(config.mlpHiddenLayers) || any(~isfinite(config.mlpHiddenLayers)) || ...
        any(config.mlpHiddenLayers < 1)
    error('MainGUI:TscoreMLPLayers', ...
        'MLP hidden layers must contain positive integers, for example 20,10.');
end
config.mlpHiddenLayers = round(config.mlpHiddenLayers(:).');
config.maxPLSRank = round(config.maxPLSRank);
if ~isempty(config.fixedPLSRank)
    config.fixedPLSRank = round(config.fixedPLSRank);
    if config.fixedPLSRank > config.maxPLSRank
        error('MainGUI:TscoreFixedPLSRank', ...
            'Fixed PLS component count cannot exceed the maximum PLS rank.');
    end
end
config.mlpMaxEpochs = round(config.mlpMaxEpochs);
config.cnnMaxEpochs = round(config.cnnMaxEpochs);
config.cnnMiniBatchSize = round(config.cnnMiniBatchSize);
config.randomSeed = round(config.randomSeed);
config.svrInnerFolds = max(2,round(config.svrInnerFolds));
config.svrMaxCandidates = round(config.svrMaxCandidates);
end

function ratioNames = localValidateRatioNames(rawNames)
allowed = ["PO4_CO3" "PO4_AmideIII" "PO4_CH2" ...
    "PO4_AmideI" "CO3_AmideIII"];
ratioNames = string(rawNames);
ratioNames = strtrim(ratioNames(:).');
ratioNames(strlength(ratioNames) == 0) = [];
if numel(ratioNames) == 1 && any(strcmpi(ratioNames,["all" "*"]))
    ratioNames = allowed;
    return
end
canonical = strings(size(ratioNames));
for k = 1:numel(ratioNames)
    match = find(strcmpi(ratioNames(k),allowed),1,'first');
    if isempty(match)
        error('MainGUI:TscoreRatios', ...
            'Unknown Raman ratio "%s". Select ratios using the T-score configuration window.', ...
            ratioNames(k));
    end
    canonical(k) = allowed(match);
end
ratioNames = unique(canonical,'stable');
end

function localPositiveScalar(value, label)
if ~isscalar(value) || ~isfinite(value) || value <= 0
    error('MainGUI:TscoreNumericSetting', '%s must be a positive number.', label);
end
end

function localNonnegativeScalar(value, label)
if ~isscalar(value) || ~isfinite(value) || value < 0
    error('MainGUI:TscoreNumericSetting', '%s must be zero or a positive number.', label);
end
end

function localPositiveVector(value, label)
if isempty(value) || any(~isfinite(value)) || any(value <= 0)
    error('MainGUI:TscoreNumericSetting', ...
        '%s must contain positive numbers.', label);
end
end

function localNonnegativeVector(value, label)
if isempty(value) || any(~isfinite(value)) || any(value < 0)
    error('MainGUI:TscoreNumericSetting', ...
        '%s must contain zero or positive numbers.', label);
end
end
