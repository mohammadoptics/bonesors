function data = getFieldData(dataStruct, fieldPath)
    % Retrieve data from nested fields given a dot-separated path
    try
        data = dataStruct;
        tokens = regexp(fieldPath, '\.|\{|\}', 'split');
        for i = 1:length(tokens)
            token = tokens{i};
            if isempty(token)
                continue;
            elseif all(isstrprop(token, 'digit'))
                idx = str2double(token);
                data = data{idx};
            else
                data = data.(token);
            end
        end
    catch
        data = [];
        warning('Could not retrieve data for field path: %s', fieldPath);
    end
end
