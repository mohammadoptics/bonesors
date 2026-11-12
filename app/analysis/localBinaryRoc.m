function [fpr, tpr, aucVal] = localBinaryRoc(labels, scores)
    labels = logical(labels(:));
    scores = scores(:);
    keep = isfinite(scores);
    labels = labels(keep);
    scores = scores(keep);

    if numel(unique(labels)) < 2
        fpr = [0; 1];
        tpr = [0; 1];
        aucVal = NaN;
        return
    end

    [scoresSorted, ord] = sort(scores, 'descend');
    labelsSorted = labels(ord);
    P = sum(labelsSorted);
    N = sum(~labelsSorted);

    tpr = [0; cumsum(labelsSorted) ./ max(P, eps)];
    fpr = [0; cumsum(~labelsSorted) ./ max(N, eps)];

    scoreChange = [true; diff(scoresSorted) ~= 0];
    keepPts = [scoreChange; true];
    tpr = tpr(keepPts);
    fpr = fpr(keepPts);

    aucVal = trapz(fpr, tpr);
end

