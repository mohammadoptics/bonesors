function [xAxis, xLabel, axisMode] = localAutoscaleXAxis(wn, nFeatures)
    if ~isempty(wn) && nFeatures == numel(wn)
        xAxis = wn(:).';
        xLabel = 'Wavenumber (cm^{-1})';
        axisMode = "wavenumber";
    else
        xAxis = 1:nFeatures;
        xLabel = 'Feature index';
        axisMode = "feature";
    end
end

