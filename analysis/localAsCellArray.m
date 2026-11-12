function dataCells = localAsCellArray(data)
    if iscell(data)
        dataCells = data(:);
        return
    end

    if isnumeric(data) && ismatrix(data)
        dataCells = {data};
        return
    end

    dataCells = {};
end

