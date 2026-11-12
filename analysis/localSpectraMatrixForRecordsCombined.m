function [wn, X] = localSpectraMatrixForRecordsCombined(records, featureSettings, useIanitaJ)
    if nargin < 3 || isempty(useIanitaJ)
        useIanitaJ = false;
    end

    wn = [];
    X = [];
    if isempty(records)
        return
    end

    for r = 1:numel(records)
        if isempty(records(r).Spectrum)
            continue
        end

        thisSpec = localBuildRatioSpectrum(records(r).Wavenumber, ...
            records(r).Spectrum, featureSettings);
        X(end+1,:) = thisSpec(:).'; %#ok<AGROW>
        wn = records(r).Wavenumber(:);
    end

    if isempty(X)
        return
    end

    X = localApplyAverageSpectrumPreprocessing(wn, X, useIanitaJ);
end

