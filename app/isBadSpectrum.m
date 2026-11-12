% ======================================================================
%  helper – TRUE if the tag (or its prefix) appears in the bad-spectra map
% ======================================================================
function bad = isBadSpectrum(cadID, tag, M, tissueType)
    bad = false;
    if isempty(M), return, end

    cadID = upper(strrep(string(cadID), ' ', ''));
    keysToCheck = string(cadID);
    if nargin >= 4 && ~isempty(tissueType)
        tissueType = upper(string(tissueType));
        keysToCheck = [cadID + "_" + tissueType, cadID];
    end

    badList = strings(0,1);
    for k = 1:numel(keysToCheck)
        key = char(keysToCheck(k));
        if isKey(M, key)
            badList = [badList; string(M(key)).']; %#ok<AGROW>
        end
    end
    if isempty(badList), return, end
    if any(strcmpi(badList, "__ALL__"))
        bad = true;
        return
    end

    for b = badList
        if contains(b,"_")                          % exact tag
            if strcmpi(b,tag),  bad = true; return, end
        else                                        % prefix only
            if startsWith(tag,b,'IgnoreCase',true), bad = true; return, end
        end
    end
end
