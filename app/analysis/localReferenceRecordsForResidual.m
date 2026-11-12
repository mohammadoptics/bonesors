function referenceRecords = localReferenceRecordsForResidual(records, categoryName, residualReferenceMode)
    if strcmpi(string(residualReferenceMode), "category")
        referenceRecords = records(strcmpi(string({records.Category}), string(categoryName)));
    else
        referenceRecords = records;
    end
end

