function label = localRatioPLabel(p)
    if isnan(p)
        label = "ns";
    elseif p <= 1e-4
        label = "****";
    elseif p <= 1e-3
        label = "***";
    elseif p <= 1e-2
        label = "**";
    elseif p <= 5e-2
        label = "*";
    else
        label = "ns";
    end
end

