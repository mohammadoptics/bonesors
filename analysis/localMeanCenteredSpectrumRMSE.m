function rmseVal = localMeanCenteredSpectrumRMSE(measured, predicted, referenceMean)
    if isempty(referenceMean)
        rmseVal = NaN;
        return
    end
    measured = measured(:);
    predicted = predicted(:);
    referenceMean = referenceMean(:);
    if numel(measured) ~= numel(predicted) || numel(measured) ~= numel(referenceMean)
        rmseVal = NaN;
        return
    end
    measuredCentered = measured - referenceMean;
    predictedCentered = predicted - referenceMean;
    keep = isfinite(measuredCentered) & isfinite(predictedCentered);
    if nnz(keep) < 1
        rmseVal = NaN;
        return
    end
    residualScale = sqrt(mean(measuredCentered(keep).^2, 'omitnan'));
    if ~isfinite(residualScale) || residualScale == 0
        rmseVal = NaN;
        return
    end
    rmseVal = sqrt(mean((predictedCentered(keep) - measuredCentered(keep)).^2, 'omitnan')) ./ residualScale;
end

