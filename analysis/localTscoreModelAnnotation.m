function modelLine = localTscoreModelAnnotation(modelText, bestRank)
    modelText = string(modelText);
    if startsWith(upper(modelText), "PLS")
        if isfinite(bestRank)
            modelLine = sprintf('model = PLS\nfixed rank = %d', bestRank);
        else
            modelLine = 'model = PLS';
        end
    elseif startsWith(upper(modelText), "RIDGE")
        modelLine = 'model = Ridge';
    elseif startsWith(upper(modelText), "SVR")
        modelLine = 'model = SVR';
    else
        modelLine = char(modelText);
    end
    if contains(lower(modelText),"block-scaled")
        modelLine = strrep(modelLine,'model = PLS','model = PLS (block-scaled)');
        modelLine = strrep(modelLine,'model = Ridge','model = Ridge (block-scaled)');
    end
end
