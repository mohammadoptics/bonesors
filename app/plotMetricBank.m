function hFig = plotMetricBank(metricBank, metrics, opts)

% Generic grouped scatter + mean + SD plot
% Significance formatting/statistics are controlled inside addPairwiseSignificance.m
%
% metricBank.(CATEGORY).(FIELD) = numeric vector
% metrics = struct array with fields:
%   .field
%   .label
%
% opts fields:
%   .categories
%   .colors
%   .markers
%   .figureName
%   .showSignificance
%   .jitter
%   .dotSize
%   .barWidth



    % if ~isfield(opts,'categories') || isempty(opts.categories)
    %     opts.categories = {'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
    % end
    % if ~isfield(opts,'colors') || isempty(opts.colors)
    %     opts.colors = {'b','g','r'};
    % end
    % if ~isfield(opts,'markers') || isempty(opts.markers)
    %     opts.markers = {'s','d','o'};
    % end
    % if ~isfield(opts,'figureName'),          opts.figureName = 'Metric Plot'; end
    % if ~isfield(opts,'showSignificance'),    opts.showSignificance = true; end
    % if ~isfield(opts,'showNS'),              opts.showNS = true; end
    % if ~isfield(opts,'useNonParametric'),    opts.useNonParametric = false; end
    % if ~isfield(opts,'multipleComparison'),  opts.multipleComparison = 'bonferroni'; end
    % if ~isfield(opts,'jitter'),              opts.jitter = 0.05; end
    % if ~isfield(opts,'dotSize'),             opts.dotSize = 500; end
    % if ~isfield(opts,'barWidth'),            opts.barWidth = 0.25; end

    opts.jitter = 0.07;
    opts.dotSize = 105;
    opts.barWidth = 0.18;
    opts.showSignificance = true;
    opts.printPvalues = 0;
    if ~isfield(opts,'useSummaryBoxes') || isempty(opts.useSummaryBoxes)
        opts.useSummaryBoxes = false;
    end

    cats = opts.categories;
    nCats = numel(cats);
    nM = numel(metrics);

    hFig = figure('Name', opts.figureName, 'Color', 'w');
    hLegend = gobjects(1,nCats);
    markerSizeLeg = sqrt(opts.dotSize);

    for m = 1:nM
        subplot(1,nM,m); hold on

        Ygroups = cell(1,nCats);

        for c = 1:nCats
            catName = cats{c};

            if ~isfield(metricBank, catName) || ~isfield(metricBank.(catName), metrics(m).field)
                Ygroups{c} = [];
                continue
            end

            y = metricBank.(catName).(metrics(m).field)(:);
            y = y(isfinite(y));
            Ygroups{c} = y;

            if isempty(y)
                continue
            end

            if opts.useSummaryBoxes
                localDrawMetricSummaryBar(gca, c, y, 0.58);
            end

            x = c + opts.jitter*randn(numel(y),1);

            scatter(x, y, opts.dotSize, ...
                'Marker', opts.markers{c}, ...
                'MarkerFaceColor', opts.colors{c}, ...
                'MarkerEdgeColor', opts.colors{c}, ...
                'HandleVisibility', 'off');

            if m == 1
                %legText = sprintf('n=%d %s', numel(y), catName);   % or sprintf('%s (n=%d)', catName, numel(y))
                legText = sprintf('%s (n=%d)', catName, numel(y));
                hLegend(c) = plot(nan,nan, opts.markers{c}, ...
                    'MarkerFaceColor', opts.colors{c}, ...
                    'MarkerEdgeColor', opts.colors{c}, ...
                    'LineStyle','none', ...
                    'MarkerSize', markerSizeLeg, ...
                    'DisplayName', legText);
            end

            mu = mean(y,'omitnan');
            sd = std(y,'omitnan');

            errorbar(c, mu, sd, ...
                'Color', 'k', ...
                'LineWidth', 2.2, ...
                'CapSize', 11, ...
                'LineStyle', 'none', ...
                'HandleVisibility','off');

            line([c-opts.barWidth c+opts.barWidth], [mu mu], ...
                'Color', 'k', ...
                'LineWidth', 2.2, ...
                'HandleVisibility','off');
        end

        ax = gca;
        set(ax, ...
            'Box','off', ...
            'LineWidth',2.8, ...
            'XAxisLocation','bottom', ...
            'YAxisLocation','left', ...
            'XTick',1:nCats, ...
            'XTickLabel',[],...
            'FontSize',17,'FontName','Arial');

        %'XTickLabel',cats,...

        %title(metrics(m).label, 'Interpreter','tex');
        ylabel(metrics(m).label, 'Interpreter','tex', 'FontSize',18);
        xlim([0.5 3.5]);

        yall = vertcat(Ygroups{:});
        yall = yall(isfinite(yall));

        if isempty(yall)
            ylim(ax, [0 1]);
            text(ax, 0.5, 0.5, 'No valid measurements', ...
                'Units','normalized', 'HorizontalAlignment','center', ...
                'FontName','Arial', 'FontSize',12);
            continue
        end

        yMinData = min(yall);
        yMaxData = max(yall);
        yrLocal = max(yMaxData - yMinData, 1e-6*max(1,max(abs(yall))));

        newYmin = yMinData - 0.10*yrLocal;
        newYmax = yMaxData + 0.55*yrLocal;

        ylim(ax, [newYmin, newYmax]);
      

        if opts.showSignificance
            statOut = addPairwiseSignificance(ax, Ygroups, 1:nCats, ...
                'lineWidth', 2.4, ...
                'fontSizeNS', 20, ...
                'fontSizeStar', 34, ...
                'starYOffset', 0);

            if opts.printPvalues
                printPanelPvalues(m, metrics(m).label, cats, statOut);
            end
        end


        if strcmp(metrics(m).field,'Tscore')
            yline(-1,  'k-', 'LineWidth',2, 'HandleVisibility','off');
            yline(-2.5,'k-', 'LineWidth',2, 'HandleVisibility','off');
        end
    end

    validLeg = isgraphics(hLegend);
    if any(validLeg)
        lg = legend(hLegend(validLeg), 'Box','off');
        lg.ItemTokenSize = [40 markerSizeLeg+5];
    end
end


function localDrawMetricSummaryBar(ax, xCenter, y, barWidth)
    y = y(isfinite(y));
    if isempty(y)
        return
    end
    if nargin < 4 || isempty(barWidth)
        barWidth = 0.60;
    end

    mu = mean(y, 'omitnan');
    if ~isfinite(mu)
        return
    end

    bar(ax, xCenter, mu, barWidth, ...
        'FaceColor', [0.88 0.88 0.88], ...
        'EdgeColor', 'k', ...
        'LineWidth', 2.0, ...
        'HandleVisibility','off');
end


function printPanelPvalues(panelIdx, metricLabel, cats, statOut)

    if isempty(statOut)
        return
    end

    letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

    if panelIdx <= numel(letters)
        panelLetter = letters(panelIdx);
    else
        panelLetter = '?';
    end

    fprintf('\nPanel %c: %s\n', panelLetter, metricLabel);

    for k = 1:numel(statOut)

        i = statOut(k).i;
        j = statOut(k).j;

        if i > numel(cats) || j > numel(cats)
            continue
        end

        fprintf('   p(%s vs %s) = %.4f\n', ...
            cats{i}, cats{j}, statOut(k).p);
    end

    fprintf('\n');
end
