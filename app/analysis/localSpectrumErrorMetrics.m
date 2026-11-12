function [rmseVal, mapeVal, rVal] = localSpectrumErrorMetrics(measured, predicted)
    measured = measured(:);
    predicted = predicted(:);
    keep = isfinite(measured) & isfinite(predicted);
    if ~any(keep)
        rmseVal = NaN;
        mapeVal = NaN;
        rVal = NaN;
        return
    end

    err = predicted(keep) - measured(keep);
    rmseVal = sqrt(mean(err.^2, 'omitnan'));

    if nnz(keep) >= 3 && std(measured(keep), 'omitnan') > 0 && std(predicted(keep), 'omitnan') > 0
        rVal = corr(measured(keep), predicted(keep), 'Rows','complete');
    else
        rVal = NaN;
    end

    denom = abs(measured(keep));
    validPct = denom > 0.02 * max(denom);
    if any(validPct)
        mapeVal = mean(abs(err(validPct)) ./ denom(validPct), 'omitnan') * 100;
    else
        mapeVal = NaN;
    end
end

