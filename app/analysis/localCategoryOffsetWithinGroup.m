function offset = localCategoryOffsetWithinGroup(catName)
    switch upper(string(catName))
        case "NORMAL"
            offset = -0.16;
        case "OSTEOPENIA"
            offset = 0;
        case "OSTEOPOROSIS"
            offset = 0.16;
        otherwise
            offset = 0;
    end
end

