function Xproc = localApplyAverageSpectrumPreprocessing(wn, X, useIanitaJ)
    Xproc = X;
    if ~useIanitaJ
        return
    end

    if exist('IanitaJ', 'file') ~= 2
        warning('IanitaJ was requested for average spectra, but IanitaJ.m was not found. Plotting without IanitaJ.');
        return
    end

    wn = wn(:);
    polyorder = 7;
    c1 = 1;
    c2 = numel(wn);
    iter = 10;
    addlb = [];

    for k = 1:size(X, 1)
        try
            y = IanitaJ(wn, X(k,:).', polyorder, c1, c2, iter, addlb);
            Xproc(k,:) = y(:).';
        catch ME
            warning('IanitaJ failed for one average-spectrum trace (%s). Plotting without IanitaJ.', ME.message);
            Xproc = X;
            return
        end
    end
end

