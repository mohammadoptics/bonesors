function settings = localDefaultCompareTextSettings()
    settings.metricsPosition = [0.98 0.74];
    settings.residualPosition = [0.04 0.69];
    settings.showResidualTrace = true;
    settings.residualReferenceMode = "category";
    settings.showResidualAgreementPanel = false;
    settings.individualAgreementMetric = "MAPE";
    settings.averagePlotMode = "category";
    settings.errMode = "none";
    settings.primaryLabel = "Primary spectrum";
    settings.secondaryLabel = "Comparison spectrum";
end
