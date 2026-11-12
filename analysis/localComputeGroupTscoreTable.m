function summaryTable = localComputeGroupTscoreTable(context)
%LOCALCOMPUTEGROUPTSCORETABLE Build a no-plot T-score summary by tag/model.

o = context.options;
s = context.settings;
models = upper(string(context.ud.config.tscore.models));
tags = string(o.tags(:));

rows = struct('Priority',{},'Tag',{},'Model',{},'NCadavers',{}, ...
    'NRows',{},'R',{},'RMSE_CV',{},'ModelDetails',{},'Status',{});

for tagIndex = 1:numel(tags)
    tag = tags(tagIndex);
    records = localCollectPairedSpectra(context.cads, context.ud.statusMap, ...
        context.Tcat, o.tissue, o.spectrumNumbers, {char(tag)}, true, ...
        'single', o.tagMatchMode);
    availableCadavers = numel(unique(string({records.CadaverID}),'stable'));

    for model = models
        row = localEmptyRow(tagIndex, tag, model, availableCadavers, numel(records));
        if availableCadavers < 4
            row.Status = "Skipped: fewer than 4 cadavers";
            rows(end+1) = row; %#ok<AGROW>
            continue
        end

        feature = s.feature;
        feature.tscoreModel = lower(model);
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
            else
                row.Status = "Skipped: no valid prediction result";
            end
        catch ME
            row.Status = "Failed: " + string(ME.message);
        end
        rows(end+1) = row; %#ok<AGROW>
    end
end

summaryTable = struct2table(rows);
end

function row = localEmptyRow(priority, tag, model, nCadavers, nRows)
row = struct('Priority',priority, 'Tag',tag, 'Model',model, ...
    'NCadavers',nCadavers, 'NRows',nRows, 'R',NaN, 'RMSE_CV',NaN, ...
    'ModelDetails',"", 'Status',"");
end
