function result = localComputeTscorePrediction(records, tissueToUse, spectrumNumber, maxRank, featureSettings)
    result = struct('ok',false,'y',[],'yPred',[],'cats',strings(0,1), ...
        'bestRank',NaN,'featureLabel',"",'modelText',"",'rmseVal',NaN, ...
        'rVal',NaN,'nFeatures',0,'maxRank',NaN,'nCadavers',0, ...
        'foldRanks',[],'tuning',[]);

    fusionAudit=struct();
    if isfield(featureSettings,'locationCombineMode') && featureSettings.locationCombineMode~="records"
        [records,fusionAudit]=localFuseTscoreLocations(records,featureSettings);
        if numel(records)<4
            error('MainGUI:TscoreLocations','Fewer than four complete donors have all requested locations and finite predictors.');
        end
    end
    X = [];
    y = [];
    cats = strings(0,1);
    cadIDs = strings(0,1);
    blockScaled = isfield(featureSettings,'blockScaleRamanDemographics') && ...
        featureSettings.blockScaleRamanDemographics;
    blockSizes = [];
    ridgeModel = lower(string(featureSettings.tscoreModel)) == "ridge";
    matched = isfield(featureSettings,'validationProtocol') && ...
        string(featureSettings.validationProtocol)=="matchedKFold" && ...
        any(lower(string(featureSettings.tscoreModel))==["pls" "svr"]);
    blockModelOK = any(lower(string(featureSettings.tscoreModel))==["pls" "svr" "ridge" "mlp"]);
    if blockScaled && (~featureSettings.useRaman || ~blockModelOK || ...
            ~featureSettings.standardizePredictors)
        error('MainGUI:TscoreBlockScaling', ...
            'Block scaling requires combined predictors, standardization, and PLS, SVR, ridge, or MLP.');
    end
    featureLabel = localFeatureLabel(featureSettings, tissueToUse, spectrumNumber);

    for r = 1:numel(records)
        featureRow = [];

        if featureSettings.useRaman
            if isempty(records(r).Spectrum)
                continue
            end

            if isfield(records,'RamanFeatures')
                specFeatures=records(r).RamanFeatures;
            else
                specFeatures = localBuildTscoreRamanFeatures(records(r).Wavenumber, ...
                    records(r).Spectrum, featureSettings);
            end
            featureRow = [featureRow specFeatures]; %#ok<AGROW>
        end

        demoValues = [];
        if featureSettings.useAge
            demoValues(end+1) = records(r).Age; %#ok<AGROW>
        end
        if featureSettings.useSex
            demoValues(end+1) = records(r).Sex; %#ok<AGROW>
        end
        if featureSettings.useBMI
            demoValues(end+1) = records(r).BMI; %#ok<AGROW>
        end
        if isfield(featureSettings,'useWeight') && featureSettings.useWeight
            demoValues(end+1) = records(r).Weight; %#ok<AGROW>
        end
        featureRow = [featureRow demoValues]; %#ok<AGROW>
        if blockScaled
            if isempty(demoValues) || isempty(specFeatures)
                error('MainGUI:TscoreBlockScaling', ...
                    'Block scaling requires both Raman and demographic predictors.');
            end
            rowBlockSizes = [numel(specFeatures) numel(demoValues)];
            if ~isempty(blockSizes) && ~isequal(blockSizes,rowBlockSizes)
                error('MainGUI:TscoreBlockSizes','Predictor block sizes differ between records.');
            end
            blockSizes = rowBlockSizes;
        end

        if isempty(featureRow)
            errordlg(['No predictors are enabled. Turn on at least one of: ' ...
                'useRaman, useAge, useSex, useBMI, useWeight.'], ...
                'No predictors','modal');
            return
        end

        X(end+1,:) = featureRow; %#ok<AGROW>
        y(end+1,1) = records(r).Tscore; %#ok<AGROW>
        cats(end+1,1) = string(records(r).Category); %#ok<AGROW>
        cadIDs(end+1,1) = string(records(r).CadaverID); %#ok<AGROW>
    end

    % Ridge and matched PLS/SVR impute separately within every training fold.
    % Never use a held-out donor to estimate its own imputation value.
    if ridgeModel || matched
        keep = isfinite(y);
    else
        keep = all(isfinite(X),2) & isfinite(y);
    end
    X = X(keep,:);
    y = y(keep);
    cats = cats(keep);
    cadIDs = cadIDs(keep);

    uniqueCadIDs = unique(cadIDs, 'stable');
    if numel(uniqueCadIDs) < 4
        errordlg('At least 4 cadavers are needed for leave-one-out T-score prediction.', ...
            'Not enough data','modal');
        return
    end

    groupCounts = arrayfun(@(id) sum(cadIDs == id), uniqueCadIDs);
    minTrainRows = size(X,1) - max(groupCounts);
    maxRank = min([maxRank, minTrainRows-1, size(X,2)]);
    if maxRank < 1
        errordlg('At least one valid predictor and enough cadavers are required for PLS.', ...
            'Not enough predictors','modal');
        return
    end

    if matched
        [yPred,tuning,foldRanks] = localPredictTscoreMatchedKFold( ...
            X,y,cadIDs,featureSettings,maxRank,blockSizes);
        rmseCV=sqrt(mean((yPred-y).^2)); bestRank=NaN;
        modelText=sprintf('%s matched nested %d-fold selection', ...
            upper(string(featureSettings.tscoreModel)),featureSettings.matchedInnerFolds);
        if strcmpi(featureSettings.tscoreModel,'pls') && ~isempty(featureSettings.fixedPLSRank)
            bestRank=featureSettings.fixedPLSRank;
            modelText=sprintf('PLS fixed rank %d; matched preprocessing',bestRank);
        end
    else
    switch lower(string(featureSettings.tscoreModel))
        case "ridge"
            [yPred,tuning] = localPredictTscoreRidge(X,y,cadIDs,featureSettings,blockSizes);
            rmseCV = sqrt(mean((yPred-y).^2));
            bestRank = NaN;
            modelText = sprintf('Ridge nested %d-fold alpha selection',featureSettings.ridgeInnerFolds);

        case "pls"
            fixedRank = [];
            if isfield(featureSettings,'fixedPLSRank')
                fixedRank = featureSettings.fixedPLSRank;
            end
            [yPred, foldRanks, tuning] = localPredictTscorePLS(X, y, cadIDs, ...
                maxRank, fixedRank, featureSettings.standardizePredictors, blockSizes);
            rmseCV = sqrt(mean((yPred - y).^2));
            finiteRanks = foldRanks(isfinite(foldRanks));
            if ~isempty(fixedRank)
                bestRank = round(median(finiteRanks));
                modelText = sprintf('PLS fixed rank %d', bestRank);
            else
                bestRank = NaN;
                modelText = sprintf('PLS nested LOCO ranks %d-%d (median %.0f)', ...
                    min(finiteRanks), max(finiteRanks), median(finiteRanks));
            end

        case "svr"
            [yPred,tuning] = localPredictTscoreSVR(X,y,cadIDs,featureSettings,blockSizes);
            rmseCV = sqrt(mean((yPred - y).^2));
            bestRank = NaN;
            svrMode = lower(string(featureSettings.svrOptimizationMode));
            if any(svrMode == ["bayesian" "nested"])
                if svrMode == "bayesian"
                    tuningLabel = 'Bayesian nested tuning';
                else
                    tuningLabel = 'random-grid nested tuning';
                end
                modelText = sprintf(['SVR RBF %s ' ...
                    '(median C=%.3g, eps=%.3g, scale=%.3g)'], ...
                    tuningLabel, ...
                    median([tuning.BoxConstraint]),median([tuning.Epsilon]), ...
                    median([tuning.KernelScale]));
            else
                modelText = sprintf('SVR RBF C=%.3g eps=%.3g scale=%s', ...
                    featureSettings.svrBoxConstraint,featureSettings.svrEpsilon, ...
                    char(string(featureSettings.svrKernelScale)));
            end

        case "mlp"
            yPred = localPredictTscoreMLP(X, y, cadIDs, featureSettings,blockSizes);
            rmseCV = sqrt(mean((yPred - y).^2));
            bestRank = NaN;
            modelText = sprintf('MLP [%s]', ...
                strjoin(string(featureSettings.mlpHiddenLayers), ' '));

        case "cnn"
            yPred = localPredictTscoreCNN(X, y, cadIDs, featureSettings);
            rmseCV = sqrt(mean((yPred - y).^2));
            bestRank = NaN;
            modelText = '1-D CNN';

        otherwise
            error('MainGUI:UnknownTscoreModel', ...
                'Unknown T-score model: %s', featureSettings.tscoreModel);
    end

    end % original validation protocol
    if blockScaled
        modelText = sprintf('%s; block-scaled Raman/demographics [%d/%d columns]', ...
            modelText, blockSizes(1), blockSizes(2));
    end
    result.blockSizes = blockSizes;
    result.locationFusion=fusionAudit;
    if isfield(fusionAudit,'tags'), result.predictorMatrix=X; end
    result.blockScaleRamanDemographics = blockScaled;
    result.ok = true;
    result.y = y;
    result.yPred = yPred;
    result.cadIDs = cadIDs;
    result.cats = cats;
    result.bestRank = bestRank;
    result.featureLabel = string(featureLabel);
    result.modelText = string(modelText);
    if isscalar(rmseCV)
        result.rmseVal = rmseCV;
    else
        result.rmseVal = rmseCV(bestRank);
    end
    result.rVal = corr(y, yPred, 'Rows','complete');
    result.nFeatures = size(X,2);
    result.maxRank = maxRank;
    result.nCadavers = numel(uniqueCadIDs);
    if exist('foldRanks','var'), result.foldRanks = foldRanks; end
    if exist('tuning','var'), result.tuning = tuning; end
end
