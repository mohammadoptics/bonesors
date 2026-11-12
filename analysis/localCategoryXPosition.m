function xPos = localCategoryXPosition(categoryName, catList)
    xPos = NaN;
    for c = 1:numel(catList)
        if strcmpi(string(categoryName), catList{c})
            xPos = c;
            return
        end
    end
end

