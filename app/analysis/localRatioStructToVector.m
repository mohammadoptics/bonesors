function values = localRatioStructToVector(ratioStruct, featureSettingsOrNames)
    ratioNames = localNormalizeTscoreRatioSelection(featureSettingsOrNames);
    values = nan(1, numel(ratioNames));
    for k = 1:numel(ratioNames)
        name = char(ratioNames(k));
        if ~isfield(ratioStruct, name)
            error('Unknown T-score ratio "%s".', name);
        end
        values(k) = ratioStruct.(name);
    end
end

