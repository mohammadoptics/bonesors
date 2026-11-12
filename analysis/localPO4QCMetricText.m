function [metricLabel, titleText, flagRuleText] = localPO4QCMetricText(qcSettings, featureSettings, offsetLabel)
    if strcmpi(string(qcSettings.normalizationSource), "featureSettings")
        normRegion = string(featureSettings.normalizationRegion);
        normMethod = string(featureSettings.normalizationMethod);
        metricLabel = sprintf('PO_4 \\nu_1 peak after %s/%s normalization (%s)', ...
            normRegion, normMethod, offsetLabel);
        titleText = sprintf('Transcutaneous PO_4 visibility after %s/%s normalization (%s)', ...
            normRegion, normMethod, offsetLabel);
        flagRuleText = sprintf('max(PO4 band) after %s/%s normalization', normRegion, normMethod);
    else
        metricLabel = sprintf('PO_4 \\nu_1 peak / lipid peak (%s)', offsetLabel);
        titleText = sprintf('Transcutaneous PO_4 visibility after lipid normalization (%s)', offsetLabel);
        flagRuleText = 'max(PO4 band) / max(lipid band)';
    end
end

