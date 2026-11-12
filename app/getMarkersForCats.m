function marks = getMarkersForCats(selectedCats)
    allCats  = {'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
    allMarks = {'s','d','o'};

    M = containers.Map(allCats, allMarks);
    marks = cell(1,numel(selectedCats));

    for k = 1:numel(selectedCats)
        marks{k} = M(selectedCats{k});
    end
end