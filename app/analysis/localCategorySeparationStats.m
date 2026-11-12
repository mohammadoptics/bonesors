function stats = localCategorySeparationStats(records, catList, featureSettings, spectrumCol, useIanitaJ, xLimits)
    stats = struct('NOPE', NaN, 'NOP', NaN, 'OPEOP', NaN, 'Within', NaN);
    if isempty(records)
        return
    end

    catMeans = cell(1, numel(catList));
    withinVals = nan(1, numel(catList));
    wnRef = [];

    for c = 1:numel(catList)
        catRecords = records(strcmpi(string({records.Category}), catList{c}));
        [wn, Xcat] = localSpectraMatrixForRecordsColumn(catRecords, featureSettings, ...
            spectrumCol, useIanitaJ);
        if isempty(Xcat)
            continue
        end

        wnRef = wn;
        if ~isempty(xLimits)
            visible = wn >= min(xLimits) & wn <= max(xLimits);
            if any(visible)
                Xcat = Xcat(:, visible);
            end
        end

        mu = mean(Xcat, 1, 'omitnan');
        catMeans{c} = mu;
        rowDistances = sqrt(mean((Xcat - mu).^2, 2, 'omitnan'));
        withinVals(c) = mean(rowDistances, 'omitnan');
    end

    if isempty(wnRef) %#ok<NASGU>
        return
    end

    within = mean(withinVals(isfinite(withinVals) & withinVals > 0), 'omitnan');
    if ~isfinite(within) || within <= 0
        return
    end

    stats.Within = within;
    idxN = find(strcmpi(catList, 'NORMAL'), 1);
    idxOPE = find(strcmpi(catList, 'OSTEOPENIA'), 1);
    idxOP = find(strcmpi(catList, 'OSTEOPOROSIS'), 1);
    stats.NOPE = localNormalizedPairDistance(catMeans, idxN, idxOPE, within);
    stats.NOP = localNormalizedPairDistance(catMeans, idxN, idxOP, within);
    stats.OPEOP = localNormalizedPairDistance(catMeans, idxOPE, idxOP, within);
end

