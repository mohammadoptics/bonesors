function label = localTitleCaseCategory(catName)
    switch upper(string(catName))
        case "NORMAL"
            label = "Normal";
        case "OSTEOPENIA"
            label = "Osteopenia";
        case "OSTEOPOROSIS"
            label = "Osteoporosis";
        otherwise
            label = string(catName);
    end
end

