function [wn, meanSpec, nRecords] = localMeanSpectrumForRecordsCombined(records, featureSettings, useIanitaJ, finalNormRegion, finalNormMethod)
    if nargin < 3 || isempty(useIanitaJ)
        useIanitaJ = false;
    end
    if nargin < 4 || isempty(finalNormRegion)
        finalNormRegion = "none";
    end
    if nargin < 5 || isempty(finalNormMethod)
        finalNormMethod = "peak";
    end

    wn = [];
    meanSpec = [];
    nRecords = 0;

    [wn, X] = localSpectraMatrixForRecordsCombined(records, featureSettings, useIanitaJ);
    if isempty(X)
        return
    end

    meanSpec = mean(X, 1, 'omitnan').';
    if ~strcmpi(string(finalNormRegion), "none")
        [meanSpec,~,~,~,~] = normalizeSpectra(wn, meanSpec, ...
            string(finalNormRegion), string(finalNormMethod));
    end
    nRecords = size(X, 1);
end

