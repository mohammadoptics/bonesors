function result = localRunStrictPredictTscoreFromAnalyze(pairFile, workbookFile, priorityTags, ...
    spectrumNumber, maxRank, featureSettings, strictSettings)
    if isfield(featureSettings,'blockScaleRamanDemographics') && ...
            featureSettings.blockScaleRamanDemographics
        error('MainGUI:TscoreBlockScaling', ...
            ['Block-scaled demographics are supported in the dataset T-score ' ...
             'prediction, not the separate end-to-end reconstruction analysis.']);
    end
    if exist('runStrictTscoreValidation', 'file') ~= 2
        error(['strictPredictTscore requires runStrictTscoreValidation.m to be on ', ...
            'the MATLAB path.']);
    end

    priorityTags = cellstr(string(priorityTags));
    if numel(priorityTags) ~= 1
        error('MainGUI:StrictSingleTag','Strict validation requires one exact analysis location on the Analysis page, e.g. D3P1_MM00.');
    end
    analysisTag = string(priorityTags{1});
    if numel(priorityTags) > 1
        fprintf(['strictPredictTscore uses the first priorityTags entry as the ', ...
            'analysis tag: %s\n'], char(analysisTag));
    end

    outDir = string(strictSettings.outputFolder);
    askForOutputFolder = isfield(strictSettings, 'askForOutputFolder') && ...
        logical(strictSettings.askForOutputFolder);
    if askForOutputFolder
        chosenDir = uigetdir(fileparts(pairFile), ...
            'Select output folder for strict T-score and ratio-source results');
        if isequal(chosenDir, 0)
            error('No strict output folder was selected.');
        end
        outDir = string(chosenDir);
    elseif strlength(outDir) == 0
        outDir = fullfile(fileparts(pairFile), 'StrictTscoreValidation_fromAnalyze');
    end

    settings = struct();
    settings.pairedCadaversFile = string(pairFile);
    settings.workbookFile = string(workbookFile);
    settings.outputFolder = outDir;
    settings.categoriesToUse = {'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};

    settings.reconTagsToUse = strictSettings.reconTagsToUse;
    settings.intactSpectraToUse = strictSettings.intactSpectraToUse;
    settings.combineMode = strictSettings.reconCombineMode;
    settings.reconNormalizationRegion = strictSettings.reconNormalizationRegion;
    settings.reconNormalizationMethod = strictSettings.reconNormalizationMethod;
    settings.normalizePredictors = strictSettings.normalizePredictors;
    settings.normalizeResponse = strictSettings.normalizeResponse;
    settings.exposedSpectrumToPredict = strictSettings.exposedSpectrumToPredict;
    settings.reconNComponents = strictSettings.reconNComponents;
    settings.standardizeBeforeReconstructionPLS = strictSettings.standardizeBeforeReconstructionPLS;

    settings.measuredAnalysisSpectrumNumber = strictSettings.measuredAnalysisSpectrumNumber;
    settings.measuredAnalysisSpectrumCombineMode = strictSettings.measuredAnalysisSpectrumCombineMode;
    settings.measuredTscoreNormalizationRegion = strictSettings.measuredTscoreNormalizationRegion;
    settings.measuredTscoreNormalizationMethod = strictSettings.measuredTscoreNormalizationMethod;
    settings.measuredStandardizeTscorePredictors = logical(strictSettings.measuredStandardizeTscorePredictors);
    settings.measuredTscoreModel = upper(string(strictSettings.measuredTscoreModel));
    settings.measuredMaxTscoreRank = strictSettings.measuredMaxTscoreRank;
    settings.measuredFixedTscoreRank = strictSettings.measuredFixedTscoreRank;
    settings.measuredSvrBoxConstraint = strictSettings.measuredSvrBoxConstraint;
    settings.measuredSvrEpsilon = strictSettings.measuredSvrEpsilon;
    settings.measuredSvrKernelScale = strictSettings.measuredSvrKernelScale;

    settings.analysisTag = analysisTag;
    settings.analysisSpectrumNumber = spectrumNumber;
    settings.analysisSpectrumCombineMode = featureSettings.spectrumCombineMode;
    settings.tscoreNormalizationRegion = strictSettings.tscoreNormalizationRegion;
    settings.tscoreNormalizationMethod = strictSettings.tscoreNormalizationMethod;
    settings.standardizeTscorePredictors = logical(strictSettings.standardizeTscorePredictors);
    settings.tscoreModel = upper(string(strictSettings.tscoreModel));
    settings.maxTscoreRank = strictSettings.maxTscoreRank;
    settings.fixedTscoreRank = strictSettings.fixedTscoreRank;
    settings.svrBoxConstraint = strictSettings.svrBoxConstraint;
    settings.svrEpsilon = strictSettings.svrEpsilon;
    settings.svrKernelScale = strictSettings.svrKernelScale;
    for name = ["plsAlgorithm","plsMaxIterations","plsTolerance","scalingDDOF","svrKernelConvention","svrSolverTolerance"]
        settings.(name) = strictSettings.(name);
    end
    settings.saveFigure = true;
    if isfield(strictSettings, 'plotClassification')
        settings.plotClassification = logical(strictSettings.plotClassification);
    else
        settings.plotClassification = true;
    end
    if isfield(strictSettings, 'saveStrictPredictedCadavers')
        settings.saveStrictPredictedCadavers = logical(strictSettings.saveStrictPredictedCadavers);
    else
        settings.saveStrictPredictedCadavers = true;
    end
    if isfield(strictSettings, 'strictPredictedFileName')
        settings.strictPredictedFileName = strictSettings.strictPredictedFileName;
    else
        settings.strictPredictedFileName = "strictPredictedCadavers.mat";
    end

    fprintf('\nRunning strict end-to-end T-score prediction...\n');
    fprintf('This repeats reconstruction inside the donor-excluded outer T-score folds.\n');
    fprintf(['The saved strictPredictedCadavers.mat can be loaded later for ', ...
        'compareRatioPlots, displayRatios, and compareAverageSpectra.\n']);
    result = runStrictTscoreValidation(settings);
end
