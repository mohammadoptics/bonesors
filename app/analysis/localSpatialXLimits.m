function limits = localSpatialXLimits(wn, requestedLimits)
wn = wn(:);
limits = [min(wn) max(wn)];
if isempty(requestedLimits), return, end
candidate = [max(limits(1),requestedLimits(1)), ...
    min(limits(2),requestedLimits(2))];
if candidate(2) > candidate(1), limits = candidate; end
end
