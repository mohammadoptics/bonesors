function [offsetCol, offsetLabel] = localResolveQCOffset(offsetToUse)
    if isnumeric(offsetToUse)
        if numel(offsetToUse) ~= 1
            error('For plotPO4VisibilityQC, spectrumNumber must be a single T spectrum: 2 for 3-mm or 3 for 6-mm.');
        end
        offsetCol = offsetToUse;
    else
        txt = lower(strtrim(string(offsetToUse)));
        switch txt
            case {"3mm","3","offset3"}
                offsetCol = 2;
            case {"6mm","6","offset6"}
                offsetCol = 3;
            otherwise
                error('For plotPO4VisibilityQC, spectrumNumber must be "3mm", "6mm", 2, or 3.');
        end
    end

    if offsetCol == 2
        offsetLabel = "3-mm";
    elseif offsetCol == 3
        offsetLabel = "6-mm";
    else
        error('For plotPO4VisibilityQC, spectrumNumber must select intact spectrum column 2 (3-mm) or 3 (6-mm).');
    end
end

