function records = localCollectPairedSpectra(cads, statusMap, Tcat, tissueToUse, ...
        spectrumNumber, priorityTags, requireRaman, tagSelectionMode, tagMatchMode)
    records = struct('CadaverID',{},'Category',{},'Tag',{}, ...
        'Spectrum',{},'Wavenumber',{},'Tscore',{},'Age',{},'Sex',{},'BMI',{},'Weight',{});

    id2row = localBuildCategoryRowMap(Tcat);

    for c = 1:numel(cads)
        cadID = upper(string(cads(c).id));
        if startsWith(cadID, "IV")
            continue
        end
        if ~isKey(statusMap, char(cadID)) || ~isKey(id2row, char(cadID))
            continue
        end

        row = id2row(char(cadID));
        if ~requireRaman
            rec = struct();
            rec.CadaverID  = char(cadID);
            rec.Category   = statusMap(char(cadID));
            rec.Tag        = '';
            rec.Spectrum   = [];
            if isfield(cads(c),'wn'), rec.Wavenumber = cads(c).wn(:); else, rec.Wavenumber = []; end
            rec.Tscore     = Tcat.('Distal Radius T-Score (1/3)')(row);
            rec.Age        = localGetNumericTableValue(Tcat, row, 'Age');
            rec.Sex        = localEncodeSex(localGetTableValue(Tcat, row, 'Sex'));
            rec.BMI        = localGetNumericTableValue(Tcat, row, 'BMI');
            rec.Weight     = localGetWeightKg(Tcat, row);
            records(end+1) = rec; %#ok<AGROW>
            continue
        end
        if ~isfield(cads(c),'wn') || isempty(cads(c).wn)
            continue
        end

        [dataCells, listCol] = localGetTissueCells(cads(c), tissueToUse);
        if isempty(dataCells)
            continue
        end

        if ~isfield(cads(c), 'list') || isempty(cads(c).list) || ...
                size(cads(c).list,2) < listCol
            continue
        end
        availableTags = strings(size(cads(c).list,1), 1);
        for listRow = 1:numel(availableTags)
            availableTags(listRow) = localGetTagFromList(cads(c), listRow, listCol);
        end
        specRows = selectTagRows(availableTags, priorityTags, ...
            tagSelectionMode, tagMatchMode);
        specRows = specRows(specRows <= numel(dataCells));
        if isempty(specRows), continue, end

        for specIdx = specRows
            selectedSpectrum = [];
            if requireRaman
                specMat = dataCells{specIdx};
                if isempty(specMat) || ~ismatrix(specMat) || ...
                        size(specMat,2) < max(spectrumNumber)
                    continue
                end
                selectedSpectrum = specMat(:, spectrumNumber);
            end

            rec = struct();
            rec.CadaverID  = char(cadID);
            rec.Category   = statusMap(char(cadID));
            rec.Tag        = localGetTagFromList(cads(c), specIdx, listCol);
            rec.Spectrum   = selectedSpectrum;
            rec.Wavenumber = cads(c).wn(:);
            rec.Tscore     = Tcat.('Distal Radius T-Score (1/3)')(row);
            rec.Age        = localGetNumericTableValue(Tcat, row, 'Age');
            rec.Sex        = localEncodeSex(localGetTableValue(Tcat, row, 'Sex'));
            rec.BMI        = localGetNumericTableValue(Tcat, row, 'BMI');
            rec.Weight     = localGetWeightKg(Tcat, row);
            records(end+1) = rec; %#ok<AGROW>
        end
    end
end
