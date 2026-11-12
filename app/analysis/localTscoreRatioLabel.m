function label = localTscoreRatioLabel(ratioName, useTex)
%LOCALTSCORERATIOLABEL Display label for a selectable Raman ratio.

if nargin < 2
    useTex = false;
end

switch string(ratioName)
    case "PO4_CO3"
        plain = "PO4 / CO3";
        tex = "PO_{4}^{3-} / CO_{3}^{2-}";
    case "PO4_AmideIII"
        plain = "PO4 / Amide III";
        tex = "PO_{4}^{3-} / Amide III";
    case "PO4_CH2"
        plain = "PO4 / CH2";
        tex = "PO_{4}^{3-} / CH_{2}";
    case "PO4_AmideI"
        plain = "PO4 / Amide I";
        tex = "PO_{4}^{3-} / Amide I";
    case "CO3_AmideIII"
        plain = "CO3 / Amide III";
        tex = "CO_{3}^{2-} / Amide III";
    otherwise
        plain = string(ratioName);
        tex = plain;
end

if useTex
    label = tex;
else
    label = plain;
end
end
