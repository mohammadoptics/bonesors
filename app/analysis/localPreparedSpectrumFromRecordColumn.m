function [wn, spec] = localPreparedSpectrumFromRecordColumn(record, featureSettings, spectrumCol, useIanitaJ)
    wn = [];
    spec = [];
    if isempty(record) || isempty(record.Spectrum) || size(record.Spectrum, 2) < spectrumCol
        return
    end
    wn = record.Wavenumber(:);
    spec = localBuildRatioSpectrum(wn, record.Spectrum(:, spectrumCol), featureSettings);
    spec = localApplyAverageSpectrumPreprocessing(wn, spec(:).', useIanitaJ).';
    spec = localNormalizeWithFeatureSettings(wn, spec, featureSettings);
end

