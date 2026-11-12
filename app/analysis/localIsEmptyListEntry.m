function tf = localIsEmptyListEntry(x)
    if isempty(x)
        tf = true;
        return
    end
    sx = string(x);
    tf = all(ismissing(sx) | strlength(strtrim(sx)) == 0);
end

