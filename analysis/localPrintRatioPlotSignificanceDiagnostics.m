function localPrintRatioPlotSignificanceDiagnostics(ratioBankActual, ratioBankPredicted, metrics, catList, rowNames)
    banks = {ratioBankActual, ratioBankPredicted};
    pairNames = {'N vs OPE','N vs OP','OPE vs OP'};
    pairs = [1 2; 1 3; 2 3];

    fprintf('\n=== Ratio plot significance diagnostics ===================\n');
    fprintf('Statistics match addPairwiseSignificance: ttest2, Bonferroni over available category pairs.\n');
    for b = 1:numel(banks)
        fprintf('\n%s\n', rowNames{b});
        fprintf('%-15s  %-17s  %-17s  %-17s  %-12s  %-12s  %-8s\n', ...
            'Ratio','N median (n)','OPE median (n)','OP median (n)','N-OP p','N-OP pAdj','stars');
        for m = 1:numel(metrics)
            fld = metrics(m).field;
            Ygroups = cell(1, numel(catList));
            for c = 1:numel(catList)
                Ygroups{c} = banks{b}.(catList{c}).(fld);
                Ygroups{c} = Ygroups{c}(isfinite(Ygroups{c}));
            end

            pRaw = nan(size(pairs,1),1);
            for p = 1:size(pairs,1)
                y1 = Ygroups{pairs(p,1)};
                y2 = Ygroups{pairs(p,2)};
                if ~isempty(y1) && ~isempty(y2)
                    [~, pRaw(p)] = ttest2(y1, y2);
                end
            end
            mValid = sum(~isnan(pRaw));
            pAdj = min(pRaw .* mValid, 1);
            nOpIdx = find(strcmp(pairNames, 'N vs OP'), 1);

            medText = cell(1, numel(catList));
            for c = 1:numel(catList)
                medText{c} = sprintf('%.6g (%d)', median(Ygroups{c}, 'omitnan'), numel(Ygroups{c}));
            end
            fprintf('%-15s  %-17s  %-17s  %-17s  %-12.4g  %-12.4g  %-8s\n', ...
                fld, medText{1}, medText{2}, medText{3}, ...
                pRaw(nOpIdx), pAdj(nOpIdx), localRatioPLabel(pAdj(nOpIdx)));
        end
    end
    fprintf('==========================================================\n\n');
end

