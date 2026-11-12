function [wn, meanSpec, nRecords] = localMeanSpectrumForRecordsColumn(records, featureSettings, spectrumCol, useIanitaJ)
    if nargin < 4 || isempty(useIanitaJ)
        useIanitaJ = false;
    end

    wn = [];
    meanSpec = [];
    nRecords = 0;

    if isempty(records)
        return
    end

    X = [];
    for r = 1:numel(records)
        if isempty(records(r).Spectrum) || size(records(r).Spectrum, 2) < spectrumCol
            continue
        end

        thisSpec = localBuildRatioSpectrum(records(r).Wavenumber, ...
            records(r).Spectrum(:, spectrumCol), featureSettings);
        if isempty(thisSpec) || ~any(isfinite(thisSpec(:)))
            continue
        end
        X(end+1,:) = thisSpec(:).'; %#ok<AGROW>
        wn = records(r).Wavenumber(:);
    end

    if isempty(X)
        return
    end

    X = localApplyAverageSpectrumPreprocessing(wn, X, useIanitaJ);
    meanSpec = mean(X, 1, 'omitnan').';
    meanSpec = localNormalizeWithFeatureSettings(wn, meanSpec, featureSettings);
    nRecords = size(X, 1);
end

