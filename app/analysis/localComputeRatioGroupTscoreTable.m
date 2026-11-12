function [summaryTable,plotEntries] = localComputeRatioGroupTscoreTable(context, ratioNames)
%LOCALCOMPUTERATIOGROUPTSCORETABLE Build a no-plot summary by ratio/model.

o = context.options;
s = context.settings;
models = upper(string(context.ud.config.tscore.models));
ratioNames = localNormalizeTscoreRatioSelection(ratioNames);

records = localCollectPairedSpectra(context.cads, context.ud.statusMap, ...
    context.Tcat, o.tissue, o.spectrumNumbers, o.tags, true, ...
    o.tagSelectionMode, o.tagMatchMode);
availableCadavers = numel(unique(string({records.CadaverID}),'stable'));

rows = struct('Ratio',{},'Model',{},'NCadavers',{},'NRows',{}, ...
    'R',{},'RMSE_CV',{},'ModelDetails',{},'Status',{});
plotEntries = struct('RatioName',{},'Model',{},'FeatureSettings',{}, ...
    'Result',{},'Status',{});

for ratioIndex = 1:numel(ratioNames)
    ratioName = ratioNames(ratioIndex);
    for model = models
        row = localEmptyRow(ratioName, model, availableCadavers, numel(records));
        feature = s.feature;
        feature.tscoreModel = lower(model);
        feature.tscoreRatioNames = ratioName;
        feature.tscoreFeatureMode = localRatioFeatureMode( ...
            feature.tscoreFeatureMode, o.spectrumCombineMode);
        entry = localEmptyPlotEntry(ratioName,model,feature);
        if availableCadavers < 4
            row.Status = "Skipped: fewer than 4 cadavers";
            entry.Status = row.Status;
            rows(end+1) = row; %#ok<AGROW>
            plotEntries(end+1) = entry; %#ok<AGROW>
            continue
        end

        try
            result = localComputeTscorePrediction(records, o.tissue, ...
                o.spectrumNumbers, s.maxRank, feature);
            if result.ok
                row.NCadavers = result.nCadavers;
                row.NRows = numel(result.y);
                row.R = result.rVal;
                row.RMSE_CV = result.rmseVal;
                row.ModelDetails = result.modelText;
                row.Status = "OK";
                entry.Result = result;
                entry.Status = "OK";
            else
                row.Status = "Skipped: no valid prediction result";
                entry.Status = row.Status;
            end
        catch ME
            row.Status = "Failed: " + string(ME.message);
            entry.Status = row.Status;
        end
        rows(end+1) = row; %#ok<AGROW>
        plotEntries(end+1) = entry; %#ok<AGROW>
    end
end

summaryTable = struct2table(rows);
end

function mode = localRatioFeatureMode(configuredMode, spectrumCombineMode)
mode = string(configuredMode);
ratioModes = ["ratios" "ratiosConcat" "ratiosMeanDiff" "ratiosNormDiff"];
if ~any(mode == ratioModes)
    mode = "ratios";
end
if lower(string(spectrumCombineMode)) == "concat"
    mode = "ratiosConcat";
end
end

function row = localEmptyRow(ratioName, model, nCadavers, nRows)
row = struct('Ratio',localTscoreRatioLabel(ratioName,false), 'Model',model, ...
    'NCadavers',nCadavers, 'NRows',nRows, 'R',NaN, 'RMSE_CV',NaN, ...
    'ModelDetails',"", 'Status',"");
end

function entry = localEmptyPlotEntry(ratioName,model,feature)
entry = struct('RatioName',string(ratioName), 'Model',string(model), ...
    'FeatureSettings',feature, 'Result',[], 'Status',"");
end
