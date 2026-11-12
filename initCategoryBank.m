function bank = initCategoryBank(catList, emptyTemplate)
    bank = struct();
    for k = 1:numel(catList)
        bank.(catList{k}) = emptyTemplate;
    end
end