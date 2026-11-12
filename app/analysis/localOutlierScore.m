function [score, isOutlier, lowerFence, upperFence] = localOutlierScore(values, method, outlierSettings)
    values = values(:);
    score = nan(size(values));
    isOutlier = false(size(values));
    lowerFence = nan(size(values));
    upperFence = nan(size(values));

    finite = isfinite(values);
    x = values(finite);
    if numel(x) < 4
        return
    end

    switch lower(string(method))
        case "iqr"
            q = prctile(x, [25 75]);
            iqrVal = q(2) - q(1);
            lo = q(1) - outlierSettings.iqrMultiplier * iqrVal;
            hi = q(2) + outlierSettings.iqrMultiplier * iqrVal;

            lowerFence(finite) = lo;
            upperFence(finite) = hi;
            isOutlier(finite) = x < lo | x > hi;

            if isfinite(iqrVal) && iqrVal > 0
                below = x < lo;
                above = x > hi;
                scoreValues = zeros(size(x));
                scoreValues(below) = (x(below) - lo) ./ iqrVal;
                scoreValues(above) = (x(above) - hi) ./ iqrVal;
                score(finite) = scoreValues;
            else
                score(finite) = 0;
            end

        case "robustz"
            z = localRobustZ(values);
            score = z;
            isOutlier = abs(z) >= outlierSettings.robustZThreshold;
    end
end

