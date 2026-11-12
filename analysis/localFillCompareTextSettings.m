function settings = localFillCompareTextSettings(settings)
    defaults = localDefaultCompareTextSettings();
    if ~isfield(settings, 'metricsPosition') || isempty(settings.metricsPosition)
        settings.metricsPosition = defaults.metricsPosition;
    end
    if ~isfield(settings, 'residualPosition') || isempty(settings.residualPosition)
        settings.residualPosition = defaults.residualPosition;
    end
    if ~isfield(settings, 'showResidualTrace') || isempty(settings.showResidualTrace)
        settings.showResidualTrace = defaults.showResidualTrace;
    end
    if ~isfield(settings, 'residualReferenceMode') || isempty(settings.residualReferenceMode)
        settings.residualReferenceMode = defaults.residualReferenceMode;
    end
    settings.residualReferenceMode = validatestring(settings.residualReferenceMode, {'category','all'});
    if ~isfield(settings, 'showResidualAgreementPanel') || isempty(settings.showResidualAgreementPanel)
        settings.showResidualAgreementPanel = defaults.showResidualAgreementPanel;
    end
    settings.showResidualAgreementPanel = logical(settings.showResidualAgreementPanel);
    if ~isfield(settings, 'individualAgreementMetric') || isempty(settings.individualAgreementMetric)
        settings.individualAgreementMetric = defaults.individualAgreementMetric;
    end
    settings.individualAgreementMetric = validatestring(settings.individualAgreementMetric, {'r_res','residualRMSE','MAPE'});
    if ~isfield(settings, 'averagePlotMode') || isempty(settings.averagePlotMode)
        settings.averagePlotMode = defaults.averagePlotMode;
    end
    settings.averagePlotMode = validatestring(settings.averagePlotMode, {'category','categoryOffset','allCadavers'});
    if ~isfield(settings, 'errMode') || isempty(settings.errMode)
        settings.errMode = defaults.errMode;
    end
    settings.errMode = localValidateAverageErrMode(settings.errMode);
    if ~isfield(settings, 'primaryLabel') || strlength(string(settings.primaryLabel)) == 0
        settings.primaryLabel = defaults.primaryLabel;
    end
    if ~isfield(settings, 'secondaryLabel') || strlength(string(settings.secondaryLabel)) == 0
        settings.secondaryLabel = defaults.secondaryLabel;
    end
    settings.primaryLabel = char(string(settings.primaryLabel));
    settings.secondaryLabel = char(string(settings.secondaryLabel));
end
