function ratioBank = localBuildRatioBankFromRecords(records, catList, featureSettings)
    emptyS = struct('PO4_CO3',[],'PO4_AmideIII',[],'PO4_CH2',[], ...
        'PO4_AmideI',[],'CO3_AmideIII',[]);
    ratioBank = initCategoryBank(catList, emptyS);

    for r = 1:numel(records)
        ratioStruct = localBuildRatioStruct(records(r).Wavenumber, ...
            records(r).Spectrum, featureSettings);
        ratioFields = fieldnames(ratioStruct);

        for k = 1:numel(ratioFields)
            fld = ratioFields{k};
            val = ratioStruct.(fld);
            if isfinite(val)
                ratioBank.(records(r).Category).(fld)(end+1,1) = val; %#ok<AGROW>
            else
                ratioBank.(records(r).Category).(fld)(end+1,1) = NaN; %#ok<AGROW>
            end
        end
    end
end

