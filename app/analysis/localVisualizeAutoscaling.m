function localVisualizeAutoscaling(records, tissueToUse, spectrumNumber, featureSettings, exampleCadaverID)
    X = [];
    cats = strings(0,1);
    cadIDs = strings(0,1);
    wn = [];

    for r = 1:numel(records)
        if isempty(records(r).Spectrum)
            continue
        end
        featureRow = localBuildTscoreRamanFeatures(records(r).Wavenumber, ...
            records(r).Spectrum, featureSettings);
        if isempty(featureRow) || any(~isfinite(featureRow))
            continue
        end

        X(end+1,:) = featureRow; %#ok<AGROW>
        cats(end+1,1) = upper(string(records(r).Category)); %#ok<AGROW>
        cadIDs(end+1,1) = string(records(r).CadaverID); %#ok<AGROW>
        if isempty(wn)
            wn = records(r).Wavenumber(:);
        end
    end

    if isempty(X)
        errordlg('No Raman feature rows were available for autoscaling visualization.', ...
            'No autoscaling data','modal');
        return
    end

    uniqueCadIDs = unique(cadIDs, 'stable');
    if strlength(string(exampleCadaverID)) == 0
        testID = uniqueCadIDs(1);
    else
        testID = upper(string(exampleCadaverID));
        if ~any(strcmpi(cadIDs, testID))
            warning('Requested autoscaleExampleCadaverID "%s" was not found. Using %s instead.', ...
                char(testID), char(uniqueCadIDs(1)));
            testID = uniqueCadIDs(1);
        end
    end

    test = strcmpi(cadIDs, testID);
    train = ~test;
    if ~any(train) || ~any(test)
        errordlg('Autoscaling visualization requires at least one training and one held-out cadaver.', ...
            'Not enough data','modal');
        return
    end

    [XtrainZ, XtestZ] = localStandardizeTrainTest(X(train,:), X(test,:));
    Xz = nan(size(X));
    Xz(train,:) = XtrainZ;
    Xz(test,:) = XtestZ;

    featureLabel = localFeatureLabel(featureSettings, tissueToUse, spectrumNumber);
    [xAxis, xLabel, axisMode] = localAutoscaleXAxis(wn, size(X,2));

    catList = {'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
    catClr = containers.Map(catList, {[0 0 1], [0 1 0], [1 0 0]});

    figure('Name','Autoscaling visualization', ...
        'Color','w', 'Units','inches', 'Position',[0 0 13 8]);
    tiledlayout(2,2, 'TileSpacing','compact', 'Padding','compact');

    ax1 = nexttile;
    localPlotAutoscaleCategoryMeans(ax1, xAxis, X(train,:), cats(train), catList, catClr);
    title(ax1, 'Training features before autoscaling');
    ylabel(ax1, 'Normalized intensity / feature value');

    ax2 = nexttile;
    localPlotAutoscaleCategoryMeans(ax2, xAxis, Xz(train,:), cats(train), catList, catClr);
    title(ax2, 'Training features after autoscaling');
    ylabel(ax2, 'Training-fold z-score');
    yline(ax2, 0, ':k', 'LineWidth',1.5, 'HandleVisibility','off');

    ax3 = nexttile;
    localPlotAutoscaleHeldOut(ax3, xAxis, X(test,:), cats(test), catList, catClr, testID);
    title(ax3, sprintf('Held-out cadaver %s before autoscaling', char(testID)), 'Interpreter','none');
    xlabel(ax3, xLabel);
    ylabel(ax3, 'Normalized intensity / feature value');

    ax4 = nexttile;
    localPlotAutoscaleHeldOut(ax4, xAxis, Xz(test,:), cats(test), catList, catClr, testID);
    title(ax4, sprintf('Held-out cadaver %s after autoscaling', char(testID)), 'Interpreter','none');
    xlabel(ax4, xLabel);
    ylabel(ax4, 'Training-fold z-score');
    yline(ax4, 0, ':k', 'LineWidth',1.5, 'HandleVisibility','off');

    allAx = [ax1 ax2 ax3 ax4];
    for a = allAx
        set(a, 'FontSize',16, 'LineWidth',2, 'Box','off');
        xlim(a, [min(xAxis) max(xAxis)]);
        if strcmp(axisMode, "wavenumber")
            set(a, 'XDir','normal');
        end
    end

    fprintf('\n=== Autoscaling visualization ================================\n');
    fprintf('Predictor features: %s\n', featureLabel);
    fprintf('Held-out example cadaver: %s\n', char(testID));
    fprintf('Training rows: %d   Held-out rows: %d   Features: %d\n', ...
        sum(train), sum(test), size(X,2));
    fprintf('Autoscaling formula: X_scaled = (X - mean(training)) ./ std(training), applied feature-by-feature.\n');
    fprintf('The held-out cadaver is scaled using only training-fold mean and SD.\n');
    fprintf('==============================================================\n\n');

    localPlotAutoscaleMechanism(xAxis, xLabel, X(train,:), X(test,:), ...
        cats(test), catList, catClr, testID, axisMode);
end

