function localPlotPO4VisibilityQC(cads, statusMap, Tcat, spectrumNumber, ...
        priorityTags, qcSettings, featureSettings, pairFile, tagSelectionMode, tagMatchMode)
    qcTable = localBuildPO4VisibilityQCTable(cads, statusMap, Tcat, ...
        spectrumNumber, priorityTags, qcSettings, featureSettings, ...
        tagSelectionMode, tagMatchMode);

    if isempty(qcTable)
        errordlg('No T spectra were available for PO4 visibility QC with the selected priorityTags.', ...
            'No PO4 QC data','modal');
        return
    end

    catList = {'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
    catClr = containers.Map(catList, {'b','g','r'});
    catMarker = containers.Map(catList, {'s','d','o'});
    [~, offsetLabel] = localResolveQCOffset(spectrumNumber);
    [metricLabel, titleText, flagRuleText] = localPO4QCMetricText(qcSettings, featureSettings, offsetLabel);

    figure('Name','Transcutaneous PO4 visibility QC', 'Color','w');
    ax = axes;
    hold(ax,'on');
    xPlot = NaN(height(qcTable), 1);
    patch(ax, [0.5 3.5 3.5 0.5], ...
        [0 0 qcSettings.threshold qcSettings.threshold], ...
        [0.88 0.88 0.88], 'EdgeColor','none', 'FaceAlpha',0.55, ...
        'DisplayName','Excluded region');
    for c = 1:numel(catList)
        catName = catList{c};
        idx = strcmpi(qcTable.Category, catName);
        if ~any(idx)
            continue
        end
        xVals = localJitteredCategoryX(c, nnz(idx));
        xPlot(idx) = xVals;
        scatter(ax, xVals, qcTable.VisibilityMetric(idx), 115, ...
            'Marker',catMarker(catName), ...
            'MarkerFaceColor',catClr(catName), ...
            'MarkerEdgeColor',catClr(catName), ...
            'DisplayName', localShortCategoryLabel(catName));
    end
    yline(ax, qcSettings.threshold, '--k', 'LineWidth',2.4, ...
        'DisplayName',sprintf('Threshold = %.2f', qcSettings.threshold));
    flagged = qcTable.Flagged;
    flaggedIdx = find(flagged);
    scatter(ax, xPlot(flagged), qcTable.VisibilityMetric(flagged), 190, ...
        'Marker','o', 'MarkerEdgeColor','k', 'MarkerFaceColor','none', ...
        'LineWidth',2.0, 'DisplayName','Flagged');
    if qcSettings.labelFlagged
        for i = flaggedIdx.'
            label = sprintf('%s %s', qcTable.CadaverID(i), qcTable.Tag(i));
            xText = xPlot(i) + 0.08;
            text(ax, xText, qcTable.VisibilityMetric(i), label, ...
                'FontSize',12, 'Interpreter','none', 'VerticalAlignment','middle');
        end
    end
    ylabel(ax, metricLabel, 'Interpreter','tex');
    title(ax, titleText, 'FontWeight','bold', 'Interpreter','tex');
    legend(ax, 'Location','southeast', 'Box','off');
    xlim(ax, [0.5 3.5]);
    ylim(ax, [0 max(1, 1.08*max(qcTable.VisibilityMetric, [], 'omitnan'))]);
    set(ax, 'XTick',1:3, 'XTickLabel',{'N','OPE','OP'});
    set(ax, 'FontSize',18, 'LineWidth',2.6, 'Box','off', 'TickDir','out');
    grid(ax,'on');

    flaggedTable = qcTable(qcTable.Flagged,:);
    fprintf('\n=== Transcutaneous PO4 visibility QC =======================\n');
    fprintf('Tags used: %s\n', strjoin(string(priorityTags), ', '));
    fprintf('Offset used: %s\n', offsetLabel);
    fprintf('Normalization source: %s\n', string(qcSettings.normalizationSource));
    fprintf('Flag rule: %s < %.3f\n', flagRuleText, qcSettings.threshold);
    fprintf('PO4 band: %.0f-%.0f cm^-1   lipid band: %.0f-%.0f cm^-1\n\n', ...
        qcSettings.po4Band(1), qcSettings.po4Band(2), ...
        qcSettings.lipidBand(1), qcSettings.lipidBand(2));
    if isempty(flaggedTable)
        fprintf('No cadaver-tags were flagged by the current PO4 visibility thresholds.\n');
    else
        disp(flaggedTable(:, {'CadaverID','Category','Tag', ...
            'Offset','VisibilityMetric','PO4Peak','LipidPeak','Percentile'}));
    end
    fprintf('============================================================\n\n');

    if qcSettings.saveCSV
        [outDir,~,~] = fileparts(pairFile);
        outFile = fullfile(outDir, 'transcutaneous_PO4_visibility_QC.csv');
        writetable(qcTable, outFile);
        fprintf('Saved PO4 visibility QC table: %s\n', outFile);
    end
end

