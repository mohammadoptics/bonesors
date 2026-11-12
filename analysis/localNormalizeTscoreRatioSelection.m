function ratioNames = localNormalizeTscoreRatioSelection(featureSettingsOrNames)
    allRatioNames = ["PO4_CO3","PO4_AmideIII","PO4_CH2","PO4_AmideI","CO3_AmideIII"];

    if isstruct(featureSettingsOrNames)
        if isfield(featureSettingsOrNames, 'tscoreRatioNames')
            rawNames = featureSettingsOrNames.tscoreRatioNames;
        else
            rawNames = allRatioNames;
        end
    else
        rawNames = featureSettingsOrNames;
    end

    if isempty(rawNames)
        ratioNames = allRatioNames;
        return
    end

    ratioNames = string(rawNames);
    if numel(ratioNames) == 1 && any(strcmpi(ratioNames, ["all","*"]))
        ratioNames = allRatioNames;
        return
    end

    ratioNames = ratioNames(:).';
    keep = false(size(ratioNames));
    for k = 1:numel(ratioNames)
        match = strcmpi(ratioNames(k), allRatioNames);
        if ~any(match)
            error(['Unknown ratio selected in featureSettings.tscoreRatioNames: "%s". ', ...
                'Use one or more of: %s'], char(ratioNames(k)), char(strjoin(allRatioNames, ', ')));
        end
        ratioNames(k) = allRatioNames(find(match, 1, 'first'));
        keep(k) = true;
    end

    ratioNames = unique(ratioNames(keep), 'stable');
    if isempty(ratioNames)
        ratioNames = allRatioNames;
    end
end

