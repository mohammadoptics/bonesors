function label = localShortTagLabel(tag)
parts = split(string(tag), "_");
if isempty(parts)
    label = string(tag);
else
    label = parts(end);
end
end
