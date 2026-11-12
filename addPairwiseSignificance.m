function statOut = addPairwiseSignificance(ax, Ygroups, xCenters, varargin)
% Supports 2-group and 3-group plots.
% Ygroups  : cell array, one cell per plotted category
% xCenters : numeric positions of those categories on x-axis

    p = inputParser;

    % ==========================================================
    % Significance appearance / statistics settings
    % Edit here if you want to change default behavior
    % ==========================================================
    addParameter(p,'alpha',0.05,@isscalar);
    addParameter(p,'showNS',false,@(x)islogical(x) || (isnumeric(x) && isscalar(x)));
    addParameter(p,'useNonParametric',false,@(x)islogical(x) || (isnumeric(x) && isscalar(x)));
    addParameter(p,'multipleComparison','bonferroni',@(s)ischar(s) || isstring(s));
    addParameter(p,'lineWidth',2.5,@isscalar);
    addParameter(p,'fontSizeNS',28,@isscalar);
    addParameter(p,'fontSizeStar',56,@isscalar);
    addParameter(p,'nsYOffset',0.0001,@isscalar);
    addParameter(p,'starYOffset',-0.012,@isscalar);
    parse(p,varargin{:});
    opts = p.Results;

    %opts.showNS = logical(opts.showNS);
    %opts.useNonParametric = logical(opts.useNonParametric);

    valid = find(~cellfun(@isempty, Ygroups));
    if numel(valid) < 2
        statOut = struct([]);
        return
    end

    Ygroups  = Ygroups(valid);
    xCenters = xCenters(valid);

    nG = numel(Ygroups);
    pairs = nchoosek(1:nG,2);

    pRaw = nan(size(pairs,1),1);
    for k = 1:size(pairs,1)
        y1 = Ygroups{pairs(k,1)};
        y2 = Ygroups{pairs(k,2)};
        y1 = y1(isfinite(y1));
        y2 = y2(isfinite(y2));

        if isempty(y1) || isempty(y2)
            continue
        end

        if opts.useNonParametric
            pRaw(k) = ranksum(y1,y2);
        else
            [~, pRaw(k)] = ttest2(y1,y2);
        end
    end

    pAdj = localCorrectPValues(pRaw, opts.multipleComparison);

    yall = vertcat(Ygroups{:});
    yall = yall(isfinite(yall));
    if isempty(yall)
        statOut = struct([]);
        return
    end

    yl = ylim(ax);
    yr = yl(2) - yl(1);   % use axis height, not data range
    yTop = yl(2);

    % bracket band placed higher and with more clearance
    upperTop  = yTop - 0.03*yr;   % top bracket
    lowerTop  = yTop - 0.11*yr;   % lower brackets

    upperBase = upperTop - 0.045*yr;
    lowerBase = lowerTop - 0.045*yr;

    S = struct('i',{},'j',{},'x1',{},'x2',{},'base',{},'top',{},'p',{},'label',{},'span',{});
    for k = 1:size(pairs,1)
        i = pairs(k,1);
        j = pairs(k,2);

        yi = Ygroups{i}; yi = yi(isfinite(yi));
        yj = Ygroups{j}; yj = yj(isfinite(yj));

        if isempty(yi) || isempty(yj)
            continue
        end

        lbl = localPLabel(pAdj(k));

        if ~(pAdj(k) < opts.alpha || opts.showNS)
            continue
        end

        S(end+1).i = i; %#ok<AGROW>
        S(end).j = j;
        S(end).x1 = xCenters(i);
        S(end).x2 = xCenters(j);

        if abs(j-i) == 1
            S(end).base = lowerBase;
            S(end).top  = lowerTop;
        else
            S(end).base = upperBase;
            S(end).top  = upperTop;
        end

        S(end).p = pAdj(k);
        S(end).label = lbl;
        S(end).span = abs(j-i);
    end

    if isempty(S)
        statOut = struct([]);
        return
    end

    spans = arrayfun(@(s) abs(s.j-s.i), S);
    [~, ord] = sort(spans, 'ascend');
    S = S(ord);

    drawn = struct('x1',{},'x2',{},'top',{});
    for k = 1:numel(S)
        top = S(k).top;
        x1 = S(k).x1;
        x2 = S(k).x2;

        line(ax,[x1 x1],[S(k).base top], ...
            'Color','k','LineWidth',opts.lineWidth,'Marker','none');
        line(ax,[x2 x2],[S(k).base top], ...
            'Color','k','LineWidth',opts.lineWidth,'Marker','none');

        % split adjacent-pair bars around the center only for 3-group plots
        if numel(xCenters) == 3 && S(k).span == 1
            xMid = xCenters(2);
            splitGap = 0;

            if x2 == xMid
                x2h = x2 - splitGap;
                line(ax,[x1 x2h],[top top], ...
                    'Color','k','LineWidth',opts.lineWidth,'Marker','none');
                xText = mean([x1 x2h]);
            elseif x1 == xMid
                x1h = x1 + splitGap;
                line(ax,[x1h x2],[top top], ...
                    'Color','k','LineWidth',opts.lineWidth,'Marker','none');
                xText = mean([x1h x2]);
            else
                line(ax,[x1 x2],[top top], ...
                    'Color','k','LineWidth',opts.lineWidth,'Marker','none');
                xText = mean([x1 x2]);
            end
        else
            line(ax,[x1 x2],[top top], ...
                'Color','k','LineWidth',opts.lineWidth,'Marker','none');
            xText = mean([x1 x2]);
        end

        fs = opts.fontSizeNS;
        yText = top + opts.nsYOffset*yr;
        vAlign = 'bottom';
        if ~strcmp(S(k).label,'ns')
            fs = opts.fontSizeStar;
            yText = top + opts.starYOffset*yr;
            vAlign = 'middle';
        end

        text(ax, xText, yText, S(k).label, ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment',vAlign, ...
            'FontSize',fs, ...
            'FontWeight','bold', ...
            'Color','k');

        drawn(end+1) = struct('x1',S(k).x1,'x2',S(k).x2,'top',top); %#ok<AGROW>
        S(k).top = top;
    end

    statOut = S;
end


function pAdj = localCorrectPValues(pRaw, method)
    pAdj = pRaw;

    switch lower(string(method))
        case "none"
            return

        case "bonferroni"
            m = sum(~isnan(pRaw));
            pAdj = min(pRaw .* m, 1);

        case "holm"
            idx = find(~isnan(pRaw));
            ps = pRaw(idx);
            [psSorted, ord] = sort(ps, 'ascend');

            m = numel(psSorted);
            adj = zeros(size(psSorted));
            for ii = 1:m
                adj(ii) = min((m - ii + 1) * psSorted(ii), 1);
            end
            for ii = m-1:-1:1
                adj(ii) = max(adj(ii), adj(ii+1));
            end

            tmp = nan(size(pRaw));
            tmp(idx(ord)) = adj;
            pAdj = tmp;

        otherwise
            error('Unknown multipleComparison method: %s', string(method));
    end
end


function lbl = localPLabel(p)
    if isnan(p)
        lbl = 'ns';
    elseif p <= 1e-4
        lbl = '****';
    elseif p <= 1e-3
        lbl = '***';
    elseif p <= 1e-2
        lbl = '**';
    elseif p <= 5e-2
        lbl = '*';
    else
        lbl = 'ns';
    end
end
