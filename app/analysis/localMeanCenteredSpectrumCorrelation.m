function rVal = localMeanCenteredSpectrumCorrelation(measured, predicted, referenceMean)
    if isempty(referenceMean)
        rVal = NaN;
        return
    end
    measured = measured(:);
    predicted = predicted(:);
    referenceMean = referenceMean(:);
    if numel(measured) ~= numel(predicted) || numel(measured) ~= numel(referenceMean)
        rVal = NaN;
        return
    end
    measuredCentered = measured - referenceMean;
    predictedCentered = predicted - referenceMean;
    keep = isfinite(measuredCentered) & isfinite(predictedCentered);
    if nnz(keep) < 3 || std(measuredCentered(keep), 'omitnan') == 0 || std(predictedCentered(keep), 'omitnan') == 0
        rVal = NaN;
        return
    end
    rVal = corr(measuredCentered(keep), predictedCentered(keep), 'Rows','complete');
end

