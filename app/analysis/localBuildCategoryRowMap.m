function id2row = localBuildCategoryRowMap(Tcat)
    ids = upper(strrep(string(Tcat.('AGR-ID')), ' ', ''));
    rows = num2cell(1:numel(ids));
    id2row = containers.Map(cellstr(ids), rows);
end

