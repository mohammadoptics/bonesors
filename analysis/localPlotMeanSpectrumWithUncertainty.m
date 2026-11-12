function [hMean, yForLimits, mu] = localPlotMeanSpectrumWithUncertainty(ax, wn, X, colorSpec, errMode, varargin)
    ip = inputParser;
    addParameter(ip, 'DisplayName', '', @(s)ischar(s)||isstring(s));
    addParameter(ip, 'LineStyle', '-', @(s)ischar(s)||isstring(s));
    addParameter(ip, 'LineWidth', 2.0, @(v)isnumeric(v)&&isscalar(v));
    addParameter(ip, 'FaceAlpha', 0.15, @(v)isnumeric(v)&&isscalar(v));
    addParameter(ip, 'YOffset', 0, @(v)isnumeric(v)&&isscalar(v));
    addParameter(ip, 'HandleVisibility', 'on', @(s)ischar(s)||isstring(s));
    parse(ip, varargin{:});

    errMode = localValidateAverageErrMode(errMode);
    wn = wn(:);
    [mu, sd, sem, ci] = localAverageSpectrumStats(X);
    if isempty(mu)
        hMean = gobjects(0);
        yForLimits = [];
        return
    end

    yOffset = ip.Results.YOffset;
    base = localColorSpecToRGB(colorSpec);
    lite = min(base + 0.55 * (1 - base), 1);
    yForLimits = mu + yOffset;

    hold(ax, 'on');
    switch lower(errMode)
        case 'none'
            lowerBand = [];
            upperBand = [];

        case 'sd-fill'
            lowerBand = mu - sd;
            upperBand = mu + sd;
            hPatch = fill(ax, [wn; flipud(wn)], ...
                [upperBand + yOffset; flipud(lowerBand + yOffset)], ...
                base, 'FaceAlpha', ip.Results.FaceAlpha, ...
                'EdgeColor','none', 'HandleVisibility','off');
            try
                uistack(hPatch, 'bottom');
            catch
            end

        case 'sd-dash'
            lowerBand = mu - sd;
            upperBand = mu + sd;
            plot(ax, wn, upperBand + yOffset, '--', 'Color', lite, ...
                'LineWidth', 1.2, 'HandleVisibility','off');
            plot(ax, wn, lowerBand + yOffset, '--', 'Color', lite, ...
                'LineWidth', 1.2, 'HandleVisibility','off');

        case 'sem-dash'
            lowerBand = mu - sem;
            upperBand = mu + sem;
            plot(ax, wn, upperBand + yOffset, '--', 'Color', lite, ...
                'LineWidth', 1.2, 'HandleVisibility','off');
            plot(ax, wn, lowerBand + yOffset, '--', 'Color', lite, ...
                'LineWidth', 1.2, 'HandleVisibility','off');

        case 'ci-fill'
            lowerBand = mu - ci;
            upperBand = mu + ci;
            hPatch = fill(ax, [wn; flipud(wn)], ...
                [upperBand + yOffset; flipud(lowerBand + yOffset)], ...
                base, 'FaceAlpha', ip.Results.FaceAlpha, ...
                'EdgeColor','none', 'HandleVisibility','off');
            try
                uistack(hPatch, 'bottom');
            catch
            end
    end

    if exist('lowerBand', 'var') && ~isempty(lowerBand)
        yForLimits = [yForLimits; lowerBand + yOffset; upperBand + yOffset];
    end

    hMean = plot(ax, wn, mu + yOffset, ...
        'Color', base, ...
        'LineStyle', char(string(ip.Results.LineStyle)), ...
        'LineWidth', ip.Results.LineWidth, ...
        'DisplayName', char(string(ip.Results.DisplayName)), ...
        'HandleVisibility', char(string(ip.Results.HandleVisibility)));
end

