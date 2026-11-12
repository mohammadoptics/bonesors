function pct = localPercentRank(values)
    values = values(:);
    pct = NaN(size(values));
    valid = isfinite(values);
    vv = values(valid);
    for i = find(valid).'
        pct(i) = 100 * mean(vv <= values(i));
    end
end

