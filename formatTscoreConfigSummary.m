function text = formatTscoreConfigSummary(config)
%FORMATTSCORECONFIGSUMMARY Compact user-facing summary for the main GUI.

source = lower(string(config.predictorSource));
if isfield(config,'figureMode') && config.figureMode=="locationComparison", source="combined"; end
switch source
    case "raman"
        predictorText = "Raman";
    case "demographics"
        predictorText = localDemographicText(config);
    otherwise
        predictorText = "Raman + " + localDemographicText(config);
end

if isfield(config,'blockScaleRamanDemographics') && config.blockScaleRamanDemographics
    predictorText = "Block-scaled " + predictorText;
end

models = upper(string(config.models));
if isempty(models)
    modelText = "no model selected";
else
    displayModels = models;
    displayModels(models == "RIDGE") = "Ridge (nested K-fold alpha)";
    if any(models == "PLS")
        if isfield(config,'fixedPLSRank') && ~isempty(config.fixedPLSRank)
            displayModels(models == "PLS") = ...
                "PLS (fixed rank " + string(round(config.fixedPLSRank)) + ")";
        else
            displayModels(models == "PLS") = "PLS (nested rank)";
        end
    end
    if isfield(config,'svrOptimizationMode')
        switch string(config.svrOptimizationMode)
            case "bayesian"
                displayModels(models == "SVR") = "SVR (Bayesian nested tuning)";
            case "nested"
                displayModels(models == "SVR") = "SVR (random-grid nested tuning)";
        end
    end
    if isfield(config,'validationProtocol') && config.validationProtocol=="matchedKFold"
        if isempty(config.fixedPLSRank)
            displayModels(models=="PLS")="PLS (matched K-fold rank)";
        end
        displayModels(models=="SVR")="SVR (matched full-grid K-fold)";
    end
    modelText = strjoin(displayModels, ", ");
end
text = sprintf('Predictors: %s   |   Models: %s   |   Validation: grouped LOCO', ...
    char(predictorText), char(modelText));
if isfield(config,'locationCombineMode') && config.locationCombineMode~="records"
    text=sprintf('%s | %d locations: %s',text,numel(config.locationTags),config.locationCombineMode);
end
if isfield(config,'figureMode') && config.figureMode=="locationComparison"
    text="Multi-panel comparison (Figure checklist) | "+string(text);
end
end

function text = localDemographicText(config)
names = strings(0,1);
if config.useAge, names(end+1) = "age"; end
if config.useSex, names(end+1) = "sex"; end
if config.useBMI, names(end+1) = "BMI"; end
if config.useWeight, names(end+1) = "weight"; end
if isempty(names)
    text = "demographics (none selected)";
else
    text = "demographics (" + strjoin(names, ", ") + ")";
end
end
