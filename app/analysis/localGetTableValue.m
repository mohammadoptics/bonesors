function raw = localGetTableValue(Tcat, row, fieldName)
    if ~ismember(fieldName, Tcat.Properties.VariableNames)
        raw = NaN;
        return
    end

    col = Tcat.(fieldName);
    raw = col(row);
end

