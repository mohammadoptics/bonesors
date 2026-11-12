function value = localGetNumericTableValue(Tcat, row, fieldName)
    raw = localGetTableValue(Tcat, row, fieldName);
    if isnumeric(raw)
        value = double(raw);
    else
        value = str2double(string(raw));
    end
end

