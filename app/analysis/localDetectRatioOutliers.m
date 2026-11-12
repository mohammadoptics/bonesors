function localDetectRatioOutliers(records, tissueToUse, spectrumNumber, featureSettings, outlierSettings, pairFile)
    ratioRows = localBuildRatioTable(records, featureSettings);

    if isempty(ratioRows)
        warndlg('No ratio values were available for outlier detection.', ...
            'No outlier data','modal');
        return
    end

    T = struct2table(ratioRows);
    ratioFields = {'PO4_CO3','PO4_AmideIII','PO4_CH2','PO4_AmideI','CO3_AmideIII'};
    method = validatestring(outlierSettings.method, {'iqr','robustZ'});
    groupMode = localResolveOutlierGroupMode(outlierSettings, tissueToUse);

    for f = 1:numel(ratioFields)
        fieldName = ratioFields{f};
        values = T.(fieldName);
        score = nan(height(T),1);
        isOutlier = false(height(T),1);
        lowerFence = nan(height(T),1);
        upperFence = nan(height(T),1);

        if strcmpi(groupMode, 'category')
            cats = unique(string(T.Category));
            for c = 1:numel(cats)
                idx = string(T.Category) == cats(c);
                [score(idx), isOutlier(idx), lowerFence(idx), upperFence(idx)] = ...
                    localOutlierScore(values(idx), method, outlierSettings);
            end
        else
            [score, isOutlier, lowerFence, upperFence] = ...
                localOutlierScore(values, method, outlierSettings);
        end

        T.([fieldName '_OutlierScore']) = score;
        T.([fieldName '_LowerFence']) = lowerFence;
        T.([fieldName '_UpperFence']) = upperFence;
        T.([fieldName '_IsOutlier']) = isOutlier;
    end

    scoreCols = strcat(ratioFields, '_OutlierScore');
    flagCols = strcat(ratioFields, '_IsOutlier');

    Z = T{:, scoreCols};
    F = T{:, flagCols};
    T.MaxAbsOutlierScore = max(abs(Z), [], 2, 'omitnan');
    T.RMSOutlierScore = sqrt(mean(Z.^2, 2, 'omitnan'));
    T.NOutlierRatios = sum(F, 2, 'omitnan');
    T.IsConsistentOutlier = T.NOutlierRatios >= outlierSettings.minOutlierRatios;
    T.OutlierRatios = strings(height(T),1);
    T.OutlierScores = strings(height(T),1);
    for rr = 1:height(T)
        hit = F(rr,:);
        if any(hit)
            T.OutlierRatios(rr) = strjoin(string(ratioFields(hit)), ', ');
            hitScores = Z(rr,hit);
            if strcmpi(method, 'robustZ')
                T.OutlierScores(rr) = strjoin(compose('%.2f', hitScores), ', ');
            else
                T.OutlierScores(rr) = strjoin(compose('%.3g', hitScores), ', ');
            end
        end
    end

    if strcmpi(method, 'robustZ')
        varNames = T.Properties.VariableNames;
        varNames{strcmp(varNames, 'MaxAbsOutlierScore')} = 'MaxAbsRobustZ';
        varNames{strcmp(varNames, 'RMSOutlierScore')} = 'RMSRobustZ';
        varNames{strcmp(varNames, 'OutlierScores')} = 'OutlierRobustZ';
        T.Properties.VariableNames = varNames;
    end

    if strcmpi(method, 'robustZ')
        sortScoreName = 'MaxAbsRobustZ';
    else
        sortScoreName = 'MaxAbsOutlierScore';
    end
    T = sortrows(T, {'IsConsistentOutlier','NOutlierRatios',sortScoreName}, ...
        {'descend','descend','descend'});

    fprintf('\n=== Ratio outlier analysis ==================================\n');
    fprintf('Tissue: %s   spectrum: %s   normalization: %s/%s   combine: %s\n', ...
        tissueToUse, mat2str(spectrumNumber), ...
        string(featureSettings.normalizationRegion), ...
        string(featureSettings.normalizationMethod), ...
        string(featureSettings.spectrumCombineMode));
    if strcmpi(method, 'iqr')
        fprintf('Method: IQR boxplot fence   multiplier: %.2f   min outlier ratios: %d   grouping: %s\n', ...
            outlierSettings.iqrMultiplier, outlierSettings.minOutlierRatios, ...
            groupMode);
    else
        fprintf('Method: robust z-score   threshold: %.2f   min outlier ratios: %d   grouping: %s\n', ...
            outlierSettings.robustZThreshold, outlierSettings.minOutlierRatios, ...
            groupMode);
    end

    flagged = T(T.IsConsistentOutlier | T.NOutlierRatios > 0, :);
    if isempty(flagged)
        fprintf('No ratio outliers found with the current threshold.\n');
    else
        if strcmpi(method, 'robustZ')
            disp(flagged(:, [{'CadaverID','Category','Tag','NOutlierRatios', ...
                'OutlierRatios','OutlierRobustZ'}, ratioFields]));
        else
            disp(flagged(:, [{'CadaverID','Category','Tag','NOutlierRatios', ...
                'OutlierRatios','OutlierScores'}, ratioFields]));
        end
    end
    fprintf('=============================================================\n\n');

    if outlierSettings.saveCSV
        if isempty(pairFile)
            outDir = pwd;
        else
            outDir = fileparts(pairFile);
        end

        outName = sprintf('ratio_outliers_%s_spectrum_%s_group_%s.csv', ...
            tissueToUse, regexprep(mat2str(spectrumNumber), '[\\[\\] ]', '_'), groupMode);
        outPath = fullfile(outDir, outName);
        writetable(T, outPath);
        fprintf('Saved ratio outlier table: %s\n', outPath);
    end
end

