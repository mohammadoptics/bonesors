function c = validateStrictTscoreConfiguration(c)
%VALIDATESTRICTTSCORECONFIGURATION Fill older configs and validate explicit settings.
d = strictTscoreDefaultConfig();
for name = string(fieldnames(d)).'
    if ~isfield(c,name), c.(name) = d.(name); end
end
c.reconTagsToUse = normalizeTagSelection(c.reconTagsToUse);
if isempty(c.reconTagsToUse), error('MainGUI:StrictSettings','Select reconstruction training tags.'); end
for name = ["intactSpectraToUse","exposedSpectrumToPredict","measuredAnalysisSpectrumNumber"]
    validateattributes(c.(name),{'numeric'},{'vector','integer','positive','finite','nonempty'});
    c.(name) = c.(name)(:).';
end
for name = ["reconNComponents","plsMaxIterations","measuredMaxTscoreRank","maxTscoreRank"]
    validateattributes(c.(name),{'numeric'},{'scalar','integer','positive','finite'});
end
for name = ["plsTolerance","svrSolverTolerance","measuredSvrBoxConstraint","measuredSvrKernelScale","svrBoxConstraint","svrKernelScale"]
    validateattributes(c.(name),{'numeric'},{'scalar','positive','finite'});
end
for name = ["measuredSvrEpsilon","svrEpsilon"]
    validateattributes(c.(name),{'numeric'},{'scalar','nonnegative','finite'});
end
for name = ["measuredFixedTscoreRank","fixedTscoreRank"]
    if ~isempty(c.(name)), validateattributes(c.(name),{'numeric'},{'scalar','integer','positive','finite'}); end
end
for name = ["reconNormalizationRegion","measuredTscoreNormalizationRegion","tscoreNormalizationRegion"]
    c.(name) = string(validatestring(c.(name),{'none','PO4','CO3','CH2','AmideI','AmideIII','FullSpectrum'}));
end
for name = ["reconNormalizationMethod","measuredTscoreNormalizationMethod","tscoreNormalizationMethod"]
    c.(name) = string(validatestring(c.(name),{'peak','peakBaseline','area'}));
end
for name = ["measuredTscoreModel","tscoreModel"], c.(name)=string(validatestring(c.(name),{'SVR','PLS'})); end
c.reconCombineMode=string(validatestring(c.reconCombineMode,{'diff','concat','mean','meanDiff'}));
c.measuredAnalysisSpectrumCombineMode=string(validatestring(c.measuredAnalysisSpectrumCombineMode,{'diff','concat','mean','meanDiff'}));
if c.reconCombineMode=="diff" && numel(c.intactSpectraToUse)>2
    error('MainGUI:StrictSettings','Reconstruction difference requires at most two columns.');
end
c.plsAlgorithm=string(validatestring(c.plsAlgorithm,{'NIPALS','SIMPLS'}));
c.svrKernelConvention=string(validatestring(c.svrKernelConvention,{'python','matlab'}));
validateattributes(c.scalingDDOF,{'numeric'},{'scalar','integer','>=',0,'<=',1});
end
