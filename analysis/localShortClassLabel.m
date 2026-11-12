function label = localShortClassLabel(catName)
    switch upper(string(catName))
        case "NORMAL"
            label = "N";
        case "OSTEOPENIA"
            label = "OPE";
        case "OSTEOPOROSIS"
            label = "OP";
        otherwise
            label = string(catName);
    end
end

