function text = formatReconstructionConfigSummary(c)
c = validateReconstructionConfiguration(c);
rankText = sprintf('PLS fixed %d',c.fixedNComponents);
if c.useInnerCVForNComponents, rankText = sprintf('PLS inner LOCO 1-%d',c.maxComponentsForCV); end
rankText = sprintf('%s (%s)',rankText,c.plsAlgorithm);
if c.reconstructionModel == "MLP"
    rankText = sprintf('Original full-spectrum MLP %s; %d epochs',mat2str(c.mlpHiddenLayerSizes),c.mlpMaxEpochs);
elseif c.reconstructionModel == "KRR_RBF"
    rankText = sprintf('KRR RBF; alpha=%g; gamma multiplier=%g',c.krrAlpha,c.krrGammaMultiplier);
elseif c.reconstructionModel == "PCA_MLP"
    rankText = sprintf('Compact PCA + MLP; %d inner donor folds; %d response PCs; %d-seed mean', ...
        c.compactInnerFolds,c.compactOutputPCs,numel(c.compactSeeds));
end
text = sprintf('T%s %s -> E%s | input %s/%s; response %s/%s | %s', ...
    mat2str(c.intactSpectraToUse),c.combineMode,mat2str(c.exposedSpectrumToPredict), ...
    c.normalizationRegion,c.normalizationMethod,c.responseNormalizationRegion, ...
    c.responseNormalizationMethod,rankText);
end
