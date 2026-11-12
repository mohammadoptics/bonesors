function metricsTable = localComputeMulticlassMetrics(C, classNames)
    K = size(C,1);
    N = sum(C(:));

    TP = zeros(K,1);
    TN = zeros(K,1);
    FP = zeros(K,1);
    FN = zeros(K,1);

    Sensitivity = zeros(K,1);
    Specificity = zeros(K,1);
    Precision   = zeros(K,1);
    Accuracy    = zeros(K,1);
    F1score     = zeros(K,1);
    OddsRatio   = nan(K,1);

    for k = 1:K
        TP(k) = C(k,k);
        FN(k) = sum(C(k,:)) - TP(k);
        FP(k) = sum(C(:,k)) - TP(k);
        TN(k) = N - TP(k) - FP(k) - FN(k);

        Precision(k)   = TP(k) / max(TP(k) + FP(k), eps);
        Sensitivity(k) = TP(k) / max(TP(k) + FN(k), eps);
        Specificity(k) = TN(k) / max(TN(k) + FP(k), eps);
        Accuracy(k)    = (TP(k) + TN(k)) / N;

        if Precision(k)==0 && Sensitivity(k)==0
            F1score(k) = 0;
        else
            F1score(k) = 2 * (Precision(k) * Sensitivity(k)) / ...
                         (Precision(k) + Sensitivity(k));
        end

        if FP(k) == 0 || FN(k) == 0
            OddsRatio(k) = NaN;
        else
            OddsRatio(k) = (TP(k) * TN(k)) / (FP(k) * FN(k));
        end
    end

    metricsTable = table(classNames(:), TP, TN, FP, FN, ...
        Precision, Sensitivity, Specificity, F1score, OddsRatio, Accuracy, ...
        'VariableNames', {'Class','TP','TN','FP','FN', ...
        'Precision','Sensitivity','Specificity','F1score','OddsRatio','Accuracy'});
end

