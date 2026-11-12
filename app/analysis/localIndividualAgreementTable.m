function rows = localIndividualAgreementTable(recordsActual, recordsPredicted, spectrumNumber, featureSettings, useIanitaJ, residualReferenceMode)
    if nargin < 6 || isempty(residualReferenceMode)
        residualReferenceMode = "category";
    end

    rows = struct('CadaverID',{},'Category',{},'SpectrumNumber',{}, ...
        'RMSE',{},'MAPE',{},'RawR',{},'ResidualR',{},'ResidualRMSE',{});

    predMap = containers.Map();
    for p = 1:numel(recordsPredicted)
        predMap(char(upper(string(recordsPredicted(p).CadaverID)))) = p;
    end

    for s = 1:numel(spectrumNumber)
        specCol = s;
        for a = 1:numel(recordsActual)
            cadID = upper(string(recordsActual(a).CadaverID));
            if ~isKey(predMap, char(cadID))
                continue
            end
            p = predMap(char(cadID));
            [wnA, actualSpec] = localPreparedSpectrumFromRecordColumn(recordsActual(a), ...
                featureSettings, specCol, useIanitaJ);
            [~, predSpec] = localPreparedSpectrumFromRecordColumn(recordsPredicted(p), ...
                featureSettings, specCol, useIanitaJ);
            if isempty(actualSpec) || isempty(predSpec) || isempty(wnA)
                continue
            end

            [rmseVal, mapeVal, rawR] = localSpectrumErrorMetrics(actualSpec, predSpec);
            referenceRecords = localReferenceRecordsForResidual(recordsActual, recordsActual(a).Category, residualReferenceMode);
            referenceMean = localReferenceMeanSpectrumForRecordsColumn(referenceRecords, ...
                featureSettings, specCol, useIanitaJ, residualReferenceMode);
            residualR = localMeanCenteredSpectrumCorrelation(actualSpec, predSpec, referenceMean);
            residualRMSE = localMeanCenteredSpectrumRMSE(actualSpec, predSpec, referenceMean);

            row = struct();
            row.CadaverID = cadID;
            row.Category = upper(string(recordsActual(a).Category));
            row.SpectrumNumber = spectrumNumber(s);
            row.RMSE = rmseVal;
            row.MAPE = mapeVal;
            row.RawR = rawR;
            row.ResidualR = residualR;
            row.ResidualRMSE = residualRMSE;
            rows(end+1) = row; %#ok<AGROW>
        end
    end
end

