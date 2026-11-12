function spectrumCol = localResolveCategoryAverageSpectrumColumn(records, requestedSpectrumNumber)
    spectrumCol = requestedSpectrumNumber;
    if isempty(records)
        return
    end

    nCols = [];
    for r = 1:numel(records)
        if isfield(records(r), 'Spectrum') && ~isempty(records(r).Spectrum)
            nCols(end+1) = size(records(r).Spectrum, 2); %#ok<AGROW>
        end
    end

    if isempty(nCols)
        return
    end

    if any(nCols >= requestedSpectrumNumber)
        spectrumCol = requestedSpectrumNumber;
    elseif requestedSpectrumNumber > 1 && any(nCols == 1)
        spectrumCol = 1;
    else
        spectrumCol = min(requestedSpectrumNumber, max(nCols));
    end
end

