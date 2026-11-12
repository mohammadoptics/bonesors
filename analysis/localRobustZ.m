function z = localRobustZ(values)
    values = values(:);
    z = nan(size(values));
    finite = isfinite(values);
    x = values(finite);

    if numel(x) < 4
        return
    end

    medX = median(x, 'omitnan');
    madX = median(abs(x - medX), 'omitnan');

    if ~isfinite(madX) || madX == 0
        q = prctile(x, [25 75]);
        scale = (q(2) - q(1)) / 1.349;
    else
        scale = madX / 0.6745;
    end

    if ~isfinite(scale) || scale == 0
        scale = std(x, 'omitnan');
    end

    if ~isfinite(scale) || scale == 0
        return
    end

    z(finite) = (x - medX) ./ scale;
end

