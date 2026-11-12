function localDisplayRatios(records, tissueToUse, spectrumNumber, featureSettings, plotSettings)
    if nargin < 5 || isempty(plotSettings)
        plotSettings = struct();
    end
    if ~isfield(plotSettings,'plotAverageSpectraFlag')
        plotSettings.plotAverageSpectraFlag = false;
    end
    if ~isfield(plotSettings,'plotFWHMFlag')
        plotSettings.plotFWHMFlag = false;
    end
    if ~isfield(plotSettings,'errMode') || isempty(plotSettings.errMode)
        plotSettings.errMode = 'none';
    end
    if ~isfield(plotSettings,'priorityTags')
        plotSettings.priorityTags = {};
    end
    if ~isfield(plotSettings,'useIanitaJForAverageSpectra')
        plotSettings.useIanitaJForAverageSpectra = false;
    end
    if ~isfield(plotSettings,'ratioSummaryBoxFlag')
        plotSettings.ratioSummaryBoxFlag = false;
    end

    catList = {'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
    catClr  = containers.Map(catList, {'b','g','r'});

    opts.categories = catList;
    opts.colors = values(catClr, catList);
    opts.markers = {'s','d','o'};
    opts.useSummaryBoxes = plotSettings.ratioSummaryBoxFlag;
    opts.figureName = sprintf('%s Ratios - spectrum %s', tissueToUse, mat2str(spectrumNumber));
    if numel(spectrumNumber) > 1 && isfield(featureSettings,'spectrumCombineMode')
        opts.figureName = sprintf('%s %s', opts.figureName, featureSettings.spectrumCombineMode);
    end
    opts.figureName = sprintf('%s | normalize first: %s (%s)', opts.figureName, ...
        featureSettings.normalizationRegion, featureSettings.normalizationMethod);
    fprintf('\nRatio display: columns %s; normalize each to %s (%s), then %s, then calculate band-area ratios.\n', ...
        mat2str(spectrumNumber), featureSettings.normalizationRegion, ...
        featureSettings.normalizationMethod, featureSettings.spectrumCombineMode);
    if numel(spectrumNumber) > 1 && string(featureSettings.spectrumCombineMode) == "diff"
        warning('MainGUI:DifferenceSpectrumRatios', ...
            ['These are band-area ratios of a normalized difference spectrum, ', ...
             'not ordinary composition ratios. Near-zero denominator areas ', ...
             'can produce very large or undefined ratios.']);
    end

    emptyS = struct('PO4_CO3',[],'PO4_AmideIII',[],'PO4_CH2',[], ...
        'PO4_AmideI',[],'CO3_AmideIII',[]);
    ratioBank = initCategoryBank(catList, emptyS);

    emptyC = struct('FWHM_PO4',[], 'FWHM_CO3',[], ...
        'FWHM_AmideIII',[], 'FWHM_CH2',[], 'FWHM_AmideI',[]);
    FWHM_Bank = initCategoryBank(catList, emptyC);

    ratios = struct( ...
        'field', {'PO4_CO3','PO4_AmideIII','PO4_CH2','PO4_AmideI','CO3_AmideIII'}, ...
        'label', {'PO_{4}^{3-}/CO_{3}^{2-}','PO_{4}^{3-}/Amide III','PO_{4}^{3-}/CH_{2}', ...
        'PO_{4}^{3-}/Amide I','CO_{3}^{2-}/Amide III'});

    FWHM_Metrics = struct( ...
        'field', {'FWHM_PO4','FWHM_CO3','FWHM_AmideIII','FWHM_CH2','FWHM_AmideI'}, ...
        'label', { ...
            'FWHM_{PO_{4}^{3-}}', ...
            'FWHM_{CO_{3}^{2-}}', ...
            'FWHM_{Amide III}', ...
            'FWHM_{CH_{2}}', ...
            'FWHM_{Amide I}'});

    Xavg = [];
    catsAvg = strings(0,1);
    wnAvg = [];
    skippedSpectrumPlots = false;

    for r = 1:numel(records)
        ratioStruct = localBuildRatioStruct(records(r).Wavenumber, ...
            records(r).Spectrum, featureSettings);
        ratioFields = fieldnames(ratioStruct);

        for k = 1:numel(ratioFields)
            fld = ratioFields{k};
            val = ratioStruct.(fld);
            if isfinite(val)
                ratioBank.(records(r).Category).(fld)(end+1,1) = val; %#ok<AGROW>
            else
                ratioBank.(records(r).Category).(fld)(end+1,1) = NaN; %#ok<AGROW>
            end
        end

        needSpectrumPlot = plotSettings.plotFWHMFlag || plotSettings.plotAverageSpectraFlag;
        canBuildSpectrum = ~(size(records(r).Spectrum,2) > 1 && localIsRatioLevelCombineMode(featureSettings));

        if needSpectrumPlot && canBuildSpectrum
            plotSpectrum = localBuildRatioSpectrum(records(r).Wavenumber, ...
                records(r).Spectrum, featureSettings);

            if plotSettings.plotFWHMFlag
                fwhmStruct = localCalcFWHMFeatures(records(r).Wavenumber, plotSpectrum);
                fwhmFields = fieldnames(fwhmStruct);
                for k = 1:numel(fwhmFields)
                    fld = fwhmFields{k};
                    val = fwhmStruct.(fld);
                    if isfinite(val)
                        FWHM_Bank.(records(r).Category).(fld)(end+1,1) = val; %#ok<AGROW>
                    else
                        FWHM_Bank.(records(r).Category).(fld)(end+1,1) = NaN; %#ok<AGROW>
                    end
                end
            end

            if plotSettings.plotAverageSpectraFlag
                Xavg(end+1,:) = plotSpectrum(:).'; %#ok<AGROW>
                catsAvg(end+1,1) = string(records(r).Category); %#ok<AGROW>
                wnAvg = records(r).Wavenumber(:);
            end
        elseif needSpectrumPlot
            skippedSpectrumPlots = true;
        end
    end

    plotMetricBank(ratioBank, ratios, opts);

    if plotSettings.plotFWHMFlag && ~skippedSpectrumPlots
        optsF = opts;
        optsF.figureName = sprintf('%s FWHM Features - spectrum %s', ...
            tissueToUse, mat2str(spectrumNumber));
        if numel(spectrumNumber) > 1 && isfield(featureSettings,'spectrumCombineMode')
            optsF.figureName = sprintf('%s %s', optsF.figureName, featureSettings.spectrumCombineMode);
        end
        plotMetricBank(FWHM_Bank, FWHM_Metrics, optsF);
    end

    if plotSettings.plotAverageSpectraFlag && ~skippedSpectrumPlots
        if isempty(Xavg)
            warndlg('No spectra were available for the average-spectrum plot.', ...
                'No average spectra','modal');
        else
            localPlotAverageSpectraPerCategory(wnAvg, Xavg, catsAvg, catList, catClr, ...
                plotSettings.priorityTags, plotSettings.errMode, ...
                plotSettings.useIanitaJForAverageSpectra);
        end
    end

    if skippedSpectrumPlots
        warning(['FWHM and average-spectrum plots were skipped because ', ...
            'ratio-level combine modes do not create a physical spectrum. ', ...
            'Use "mean", "diff", or "ratio" for spectrum-level plots.']);
    end
end
