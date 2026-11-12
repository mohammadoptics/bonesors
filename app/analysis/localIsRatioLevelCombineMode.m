function tf = localIsRatioLevelCombineMode(featureSettings)
    mode = lower(string(featureSettings.spectrumCombineMode));
    tf = any(mode == ["ratiodiff", "rationormdiff", "ratiosymnormdiff"]);
end

