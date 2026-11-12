function analysisPO4VisibilityQC(context)
o = context.options; s = context.settings;
if o.tissue ~= "T"
    error('MainGUI:PO4QCRequiresT', ...
        'PO4 visibility quality control is defined for intact/transcutaneous T spectra.');
end
localPlotPO4VisibilityQC(context.cads, context.ud.statusMap, context.Tcat, ...
    o.spectrumNumbers, o.tags, s.po4QC, s.feature, context.datasetFile, ...
    o.tagSelectionMode, o.tagMatchMode);
end
