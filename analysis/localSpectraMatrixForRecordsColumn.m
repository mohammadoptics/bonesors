function [wn, X] = localSpectraMatrixForRecordsColumn(records, featureSettings, spectrumCol, useIanitaJ)
    if nargin < 4 || isempty(useIanitaJ)
        useIanitaJ = false;
    end

    wn = [];
    X = [];
    if isempty(records)
        return
    end

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
    for k = 1:size(X, 1)
        yNorm = localNormalizeWithFeatureSettings(wn, X(k,:).', featureSettings);
        X(k,:) = yNorm(:).';
    end
end

