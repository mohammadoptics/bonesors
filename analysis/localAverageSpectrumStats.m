function [mu, sd, sem, ci] = localAverageSpectrumStats(X)
    if isempty(X)
        mu = [];
        sd = [];
        sem = [];
        ci = [];
        return
    end

    mu = mean(X, 1, 'omitnan').';
    sd = std(X, 0, 1, 'omitnan').';
    nFinite = sum(isfinite(X), 1).';
    sem = sd ./ sqrt(max(nFinite, 1));
    sem(nFinite < 1) = NaN;
    ci = 1.96 * sem;
end

