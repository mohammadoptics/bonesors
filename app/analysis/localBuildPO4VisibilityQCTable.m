function qcTable = localBuildPO4VisibilityQCTable(cads, statusMap, Tcat, ...
        spectrumNumber, priorityTags, qcSettings, featureSettings, ...
        tagSelectionMode, tagMatchMode)
    id2row = localBuildCategoryRowMap(Tcat);
    spectrumNumber = spectrumNumber(:).';
    if isscalar(spectrumNumber)
        [~, offsetLabel] = localResolveQCOffset(spectrumNumber);
    else
        offsetLabel = string(localSelectedSpectrumFeatureLabel("T", ...
            spectrumNumber, featureSettings.spectrumCombineMode));
    end
    useFeatureNormalization = strcmpi(string(qcSettings.normalizationSource), "featureSettings");
    rows = struct('CadaverID',{},'Category',{},'Tag',{}, ...
        'Offset',{},'VisibilityMetric',{},'Q_PO4_Lipid',{},'PO4Peak',{},'LipidPeak',{});

    for c = 1:numel(cads)
        cadID = upper(string(cads(c).id));
        if startsWith(cadID, "IV") || ~isKey(statusMap, char(cadID)) || ~isKey(id2row, char(cadID))
            continue
        end
        if ~isfield(cads(c),'wn') || isempty(cads(c).wn) || ~isfield(cads(c),'T') || isempty(cads(c).T)
            continue
        end

        dataCells = localAsCellArray(cads(c).T);
        availableTags = strings(numel(dataCells), 1);
        for listRow = 1:numel(dataCells)
            availableTags(listRow) = localGetTagFromList(cads(c), listRow, 2);
        end
        selectedRows = selectTagRows(availableTags, priorityTags, ...
            tagSelectionMode, tagMatchMode);
        for specIdx = selectedRows
            tag = availableTags(specIdx);

            specMat = dataCells{specIdx};
            if isempty(specMat) || ~ismatrix(specMat) || ...
                    size(specMat,2) < max(spectrumNumber)
                continue
            end

            wn = cads(c).wn(:);
            if isscalar(spectrumNumber)
                spec = specMat(:, spectrumNumber);
            else
                spec = localBuildRatioSpectrum(wn, ...
                    specMat(:, spectrumNumber), featureSettings);
            end
            if useFeatureNormalization && isscalar(spectrumNumber)
                spec = localNormalizeWithFeatureSettings(wn, spec, featureSettings);
            end
            if useFeatureNormalization
                po4Peak = localBandMax(wn, spec, qcSettings.po4Band);
                lipidPeak = localBandMax(wn, spec, qcSettings.lipidBand);
                qPO4Lipid = po4Peak;
            else
                po4Peak = localBandMax(wn, spec, qcSettings.po4Band);
                lipidPeak = localBandMax(wn, spec, qcSettings.lipidBand);
                if ~isfinite(po4Peak) || ~isfinite(lipidPeak) || lipidPeak == 0
                    qPO4Lipid = NaN;
                else
                    qPO4Lipid = po4Peak / lipidPeak;
                end
            end

            row = struct();
            row.CadaverID = string(cadID);
            row.Category = string(statusMap(char(cadID)));
            row.Tag = string(tag);
            row.Offset = string(offsetLabel);
            row.VisibilityMetric = qPO4Lipid;
            row.Q_PO4_Lipid = qPO4Lipid;
            row.PO4Peak = po4Peak;
            row.LipidPeak = lipidPeak;
            rows(end+1) = row; %#ok<AGROW>
        end
    end

    if isempty(rows)
        qcTable = table();
        return
    end

    qcTable = struct2table(rows);
    qcTable.Percentile = localPercentRank(qcTable.VisibilityMetric);
    qcTable.Flagged = qcTable.VisibilityMetric < qcSettings.threshold;
end
