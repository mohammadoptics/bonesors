function label = analysisTissueLabel(tissue)
switch upper(string(tissue))
    case "E", label = 'Exposed (E)';
    case "T", label = 'Intact/transcutaneous (T)';
    case "P", label = 'Predicted (P)';
    otherwise, label = char(string(tissue));
end
end
