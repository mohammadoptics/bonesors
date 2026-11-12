function spec = localNormalizeWithFeatureSettings(wn, spec, featureSettings)
    if isempty(spec) || ~isfield(featureSettings, 'normalizationRegion') || ...
            strcmpi(string(featureSettings.normalizationRegion), "none")
        return
    end

    normMethod = "peak";
    if isfield(featureSettings, 'normalizationMethod') && ~isempty(featureSettings.normalizationMethod)
        normMethod = string(featureSettings.normalizationMethod);
    end

    [spec,~,~,~,~] = normalizeSpectra(wn, spec(:), ...
        string(featureSettings.normalizationRegion), normMethod);
end

