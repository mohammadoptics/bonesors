function ratioRows = localBuildRatioTable(records, featureSettings)
    ratioRows = struct('CadaverID',{},'Category',{},'Tag',{}, ...
        'PO4_CO3',{},'PO4_AmideIII',{},'PO4_CH2',{}, ...
        'PO4_AmideI',{},'CO3_AmideIII',{});

    for r = 1:numel(records)
        ratioStruct = localBuildRatioStruct(records(r).Wavenumber, ...
            records(r).Spectrum, featureSettings);

        row = struct();
        row.CadaverID = string(records(r).CadaverID);
        row.Category = string(records(r).Category);
        row.Tag = string(records(r).Tag);
        row.PO4_CO3 = ratioStruct.PO4_CO3;
        row.PO4_AmideIII = ratioStruct.PO4_AmideIII;
        row.PO4_CH2 = ratioStruct.PO4_CH2;
        row.PO4_AmideI = ratioStruct.PO4_AmideI;
        row.CO3_AmideIII = ratioStruct.CO3_AmideIII;
        ratioRows(end+1) = row; %#ok<AGROW>
    end
end

