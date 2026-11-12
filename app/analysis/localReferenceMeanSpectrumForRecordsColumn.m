function referenceMean = localReferenceMeanSpectrumForRecordsColumn(records, featureSettings, spectrumCol, useIanitaJ, residualReferenceMode)
    if nargin < 5 || isempty(residualReferenceMode)
        residualReferenceMode = "category"; %#ok<NASGU>
    end

    referenceMean = [];
    if isempty(records)
        return
    end

    X = [];
    wn = [];
    for r = 1:numel(records)
        [wnThis, specThis] = localPreparedSpectrumFromRecordColumn(records(r), ...
            featureSettings, spectrumCol, useIanitaJ);
        if isempty(specThis)
            continue
        end
        X(end+1,:) = specThis(:).'; %#ok<AGROW>
        wn = wnThis;
    end
    if isempty(X) || isempty(wn)
        return
    end
    referenceMean = mean(X, 1, 'omitnan').';
end

