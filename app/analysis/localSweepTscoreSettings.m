function localSweepTscoreSettings(records, tissueToUse, spectrumNumber, maxRank, featureSettings, sweepSettings, pairFile)
    if exist('fitrsvm', 'file') ~= 2
        error(['SVR T-score sweep requires MATLAB fitrsvm ', ...
            '(Statistics and Machine Learning Toolbox).']);
    end

    Cgrid = sweepSettings.svrBoxConstraint(:);
    epsGrid = sweepSettings.svrEpsilon(:);
    scaleGrid = sweepSettings.svrKernelScale(:);

    boxValues = [];
    epsilonValues = [];
    kernelScaleValues = [];
    rValues = [];
    rmseValues = [];
    overallAccValues = [];
    balancedAccValues = [];
    macroF1Values = [];
    nCadaverValues = [];
    nFeatureValues = [];
    featureLabels = strings(0,1);
    totalRuns = numel(Cgrid) * numel(epsGrid) * numel(scaleGrid);

    fprintf('\n=== SVR T-score hyperparameter sweep =======================\n');
    fprintf('Predictors: %s spectrum %s, combine=%s, featureMode=%s, norm=%s/%s\n', ...
        tissueToUse, mat2str(spectrumNumber), ...
        char(string(featureSettings.spectrumCombineMode)), ...
        char(string(featureSettings.tscoreFeatureMode)), ...
        char(string(featureSettings.normalizationRegion)), ...
        char(string(featureSettings.normalizationMethod)));
    fprintf('Grid: C=%s   epsilon=%s   kernelScale=%s\n', ...
        mat2str(Cgrid.'), mat2str(epsGrid.'), mat2str(scaleGrid.'));
    fprintf('Total settings: %d\n', totalRuns);
    fprintf('===========================================================\n');

    for c = 1:numel(Cgrid)
        for e = 1:numel(epsGrid)
            for s = 1:numel(scaleGrid)
                fs = featureSettings;
                fs.tscoreModel = "svr";
                fs.svrBoxConstraint = Cgrid(c);
                fs.svrEpsilon = epsGrid(e);
                fs.svrKernelScale = scaleGrid(s);

                result = localComputeTscorePrediction(records, tissueToUse, spectrumNumber, maxRank, fs);
                if ~result.ok
                    continue
                end

                [overallAcc, balancedAcc, macroF1] = localTscoreClassificationSummary( ...
                    result.y, result.yPred, result.cats);

                boxValues(end+1,1) = Cgrid(c); %#ok<AGROW>
                epsilonValues(end+1,1) = epsGrid(e); %#ok<AGROW>
                kernelScaleValues(end+1,1) = scaleGrid(s); %#ok<AGROW>
                rValues(end+1,1) = result.rVal; %#ok<AGROW>
                rmseValues(end+1,1) = result.rmseVal; %#ok<AGROW>
                overallAccValues(end+1,1) = overallAcc; %#ok<AGROW>
                balancedAccValues(end+1,1) = balancedAcc; %#ok<AGROW>
                macroF1Values(end+1,1) = macroF1; %#ok<AGROW>
                nCadaverValues(end+1,1) = result.nCadavers; %#ok<AGROW>
                nFeatureValues(end+1,1) = result.nFeatures; %#ok<AGROW>
                featureLabels(end+1,1) = string(result.featureLabel); %#ok<AGROW>
            end
        end
    end

    if isempty(rValues)
        warning('SVR sweep finished, but no valid settings were produced.');
        return
    end

    rows = table(boxValues, epsilonValues, kernelScaleValues, ...
        rValues, rmseValues, overallAccValues, balancedAccValues, macroF1Values, ...
        nCadaverValues, nFeatureValues, featureLabels, ...
        'VariableNames', {'BoxConstraint','Epsilon','KernelScale', ...
        'R','RMSE_CV','OverallAccuracy','BalancedAccuracy','MacroF1', ...
        'NCadavers','NFeatures','FeatureLabel'});

    rows = sortrows(rows, {'BalancedAccuracy','R','RMSE_CV'}, ...
        {'descend','descend','ascend'});

    nPrint = min(sweepSettings.maxRowsToPrint, height(rows));
    fprintf('\nTop %d SVR settings ranked by balanced accuracy, then r, then RMSE:\n', nPrint);
    disp(rows(1:nPrint, {'BoxConstraint','Epsilon','KernelScale', ...
        'R','RMSE_CV','OverallAccuracy','BalancedAccuracy','MacroF1','NCadavers','NFeatures'}));

    if isfield(sweepSettings,'saveCSV') && sweepSettings.saveCSV
        if isempty(pairFile)
            outDir = pwd;
        else
            outDir = fileparts(pairFile);
        end
        spectrumLabel = regexprep(mat2str(spectrumNumber), '[\[\]\s]', '');
        outFile = fullfile(outDir, sprintf('svr_tscore_sweep_%s_spectrum_%s.csv', ...
            char(tissueToUse), spectrumLabel));
        writetable(rows, outFile);
        fprintf('Saved full SVR sweep table: %s\n', outFile);
    end

    fprintf('===========================================================\n\n');
end

