function c = validateReconstructionConfiguration(c)
% Migrate old enable switches to the sole normalization control: region none.
legacyFlags = {'normalizePredictors','normalizeResponse'};
regions = {'normalizationRegion','responseNormalizationRegion'};
for k = 1:2
    if isfield(c,legacyFlags{k})
        validateattributes(c.(legacyFlags{k}),{'logical','numeric'},{'scalar','binary'});
        if ~c.(legacyFlags{k}), c.(regions{k}) = "none"; end
        c = rmfield(c,legacyFlags{k});
    end
end
defaults = reconstructionDefaultConfig();
names = fieldnames(defaults);
for k = 1:numel(names)
    if ~isfield(c,names{k}), c.(names{k}) = defaults.(names{k}); end
end
c.tagsToUse = normalizeTagSelection(c.tagsToUse);
c.reconstructionModel = string(validatestring(c.reconstructionModel,{'PLS','MLP','KRR_RBF','PCA_MLP'}));
c.plsAlgorithm = string(validatestring(c.plsAlgorithm,{'NIPALS','SIMPLS'}));
c.categoriesToUse = cellstr(upper(string(normalizeTagSelection(c.categoriesToUse))));
if any(~ismember(string(c.categoriesToUse), ["NORMAL","OSTEOPENIA","OSTEOPOROSIS"]))
    error('MainGUI:ReconstructionConfig','Unknown category. Use NORMAL, OSTEOPENIA, OSTEOPOROSIS, or leave blank for all.');
end
for name = ["intactSpectraToUse","exposedSpectrumToPredict"]
    c.(name) = parseSpectrumNumbers(c.(name));
    if any(c.(name)>3)
        error('MainGUI:ReconstructionConfig','Spectrum columns must be 1 (0 mm), 2 (3 mm), or 3 (6 mm).');
    end
end
c.combineMode = string(validatestring(c.combineMode, {'concat','mean','add','diff','meanDiff'}));
if any(c.combineMode == ["diff","meanDiff"]) && numel(c.intactSpectraToUse) ~= 2
    error('MainGUI:ReconstructionConfig','Difference and mean + difference require exactly two input columns, in order.');
end
for name = ["normalizationRegion","responseNormalizationRegion"]
    c.(name) = string(validatestring(c.(name), {'none','PO4','CO3','CH2','AmideI','AmideIII','FullSpectrum'}));
end
for name = ["normalizationMethod","responseNormalizationMethod"]
    c.(name) = string(validatestring(c.(name), {'peak','peakBaseline','area'}));
end
for name = ["fixedNComponents","maxComponentsForCV","mlpMaxEpochs","plsMaxIterations"]
    validateattributes(c.(name), {'numeric'}, {'scalar','integer','positive','finite'}, mfilename, char(name));
end
validateattributes(c.plsTolerance, {'numeric'}, {'scalar','positive','finite'});
validateattributes(c.mlpHiddenLayerSizes, {'numeric'}, {'vector','integer','positive','finite'});
validateattributes(c.mlpRegularization, {'numeric'}, {'scalar','>=',0,'<=',1,'finite'});
validateattributes(c.randomSeed, {'numeric'}, {'scalar','integer','>=',0,'<=',2^32-1,'finite'});
for name = ["krrAlpha","krrGammaMultiplier"]
    validateattributes(c.(name), {'numeric'}, {'scalar','positive','finite'});
end
c.mlpTrainFcn = string(validatestring(c.mlpTrainFcn, {'trainscg','trainlm','trainbr'}));
for name = ["compactInputPCGrid","compactHiddenGrid"]
    validateattributes(c.(name),{'numeric'},{'vector','nonempty','integer','positive','finite'});
    c.(name) = unique(c.(name)(:).','stable');
end
validateattributes(c.compactAlphaGrid,{'numeric'},{'vector','nonempty','positive','finite'});
c.compactAlphaGrid = unique(c.compactAlphaGrid(:).','stable');
for name = ["compactOutputPCs","compactMaxIterations"]
    validateattributes(c.(name),{'numeric'},{'scalar','integer','positive','finite'});
end
validateattributes(c.compactInnerFolds,{'numeric'},{'scalar','integer','>=',2,'finite'});
validateattributes(c.compactInnerSeed,{'numeric'},{'scalar','integer','>=',0,'<=',2^32-1,'finite'});
validateattributes(c.compactSeeds,{'numeric'},{'vector','nonempty','integer','>=',0,'<=',2^32-1,'finite'});
if numel(unique(c.compactSeeds))~=numel(c.compactSeeds)
    error('MainGUI:ReconstructionConfig','Compact MLP initialization seeds must be distinct.');
end
c.compactSeeds = c.compactSeeds(:).';
c.compactPython = string(c.compactPython);
if ~isscalar(c.compactPython) || ...
        ~isempty(regexp(char(c.compactPython),'["\r\n%]','once'))
    error('MainGUI:ReconstructionConfig','Enter a Python executable path without quotes, percent signs or line breaks.');
end
for name = ["useInnerCVForNComponents", ...
        "standardizeBeforePLS","verifySavedFiles","createRunSubfolder"]
    validateattributes(c.(name), {'logical','numeric'}, {'scalar','binary'});
    c.(name) = logical(c.(name));
end
c.saveOutputMode = string(validatestring(c.saveOutputMode, {'individual','single','both'}));
for name = ["combinedOutputFileName","metricsFileName"]
    value = char(string(c.(name)));
    [folder,base,ext] = fileparts(value);
    expected = '.mat'; if name == "metricsFileName", expected = '.csv'; end
    if ~isempty(folder) || isempty(base) || ~strcmpi(ext,expected) || ...
            ~isempty(regexp(value, '[<>:"/\\|?*]', 'once')) || ...
            ~isempty(regexpi(base, '^(con|prn|aux|nul|com[1-9]|lpt[1-9])$', 'once'))
        error('MainGUI:ReconstructionConfig','Enter a plain %s filename, not a path.',expected);
    end
    c.(name) = string(value);
end
end
