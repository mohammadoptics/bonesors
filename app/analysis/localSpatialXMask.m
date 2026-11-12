function mask = localSpatialXMask(wn, requestedLimits)
wn = wn(:);
if isempty(requestedLimits)
    mask = true(size(wn));
else
    mask = wn >= requestedLimits(1) & wn <= requestedLimits(2);
    if ~any(mask), mask = true(size(wn)); end
end
end
