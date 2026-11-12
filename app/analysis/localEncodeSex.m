function sexValue = localEncodeSex(rawSex)
    txt = upper(strtrim(string(rawSex)));
    if startsWith(txt, "F")
        sexValue = 0;
    elseif startsWith(txt, "M")
        sexValue = 1;
    else
        sexValue = NaN;
    end
end

