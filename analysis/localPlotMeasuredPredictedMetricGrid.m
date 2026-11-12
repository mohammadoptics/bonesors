function localPlotMeasuredPredictedMetricGrid(banks, metrics, catList, catClr, rowNames, figureName, spectrumNumber, ratioSummaryBoxFlag)
    figure('Name', figureName, 'Color','w', 'Position',[30 80 1700 900]);
    tl = tiledlayout(2, numel(metrics), 'TileSpacing','loose', 'Padding','compact');

    for row = 1:2
        for m = 1:numel(metrics)
            ax = nexttile(tl);
            localPlotSingleRatioPanel(ax, banks{row}, metrics(m), catList, catClr, true, ratioSummaryBoxFlag);
            if m == 3
                ht = title(ax, sprintf('%s (%s, %s offset)', char('A' + row - 1), ...
                    rowNames{row}, localSpectrumDepthLabel(spectrumNumber(end))), ...
                    'FontSize',20, 'FontWeight','bold', 'Interpreter','none');
                ht.Units = 'normalized';
                ht.Position(2) = 1.03;
            else
                title(ax, '');
            end
        end
    end
end

