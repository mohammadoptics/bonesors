function [S_out , r_PO4_CO3 , r_PO4_AmideIII , r_PO4_CH2 , ...
          r_PO4_AmideI , r_CO3_AmideIII] = ...
          normalizeSpectra(wn , S_in , normRegion , method)
%NORMALIZESPECTRA  Normalise Raman spectra to a chosen biochemical band.
%
%   S_out = NORMALIZESPECTRA(wn , S_in , normRegion , method)
%
%   INPUTS
%     wn          – column-vector of wavenumbers (cm⁻¹)
%     S_in        – matrix of spectra, each column one spectrum
%     normRegion  – {'PO4','CO3','CH2','AmideI','AmideIII'}, default 'PO4'
%     method      – {'peak','area','peakBaseline'}, default 'peak'
%
%   OUTPUTS
%     S_out                 – normalised spectra
%     r_PO4_CO3, …          – ratios computed from AREAS (always)

    arguments
        wn (:,1) double
        S_in double
        normRegion {mustBeMember(normRegion,{'none','PO4','CO3','CH2','AmideI','AmideIII','FullSpectrum'})} = 'PO4'
        method {mustBeMember(method,{'peak','area','peakBaseline'})} = 'peak'
    end
    normRegion = char(normRegion);
    method = string(method);

    %––––––––––––––––––––––––– Region definitions –––––––––––––––––––––––––
    % First BOE exposed bone published paper
    % % region.PO4      = [ 930  990];
    % % region.CO3      = [1050 1100];
    % % region.CH2      = [1360 1500];
    % % region.AmideI   = [1550 1700];
    % % region.AmideIII = [1214 1334];

    region.PO4      = [ 930  990];
    region.CO3      = [1050 1100];
    region.CH2      = [1360 1500];
    region.AmideI   = [1595 1700];
    region.AmideIII = [1214 1334];

    useNoNormalization = strcmpi(char(normRegion), 'none');
    useFullSpectrum = strcmpi(char(normRegion), 'FullSpectrum');

    if useFullSpectrum && method == "area"
        validWn = ~isnan(wn);
        areas = nan(1,size(S_in,2));
        for j = 1:size(S_in,2)
            valid = validWn & ~isnan(S_in(:,j));
            if any(valid)
                areas(j) = trapz(wn(valid), abs(S_in(valid,j)));
            end
        end
        allSpectraDenom = mean(areas,'omitnan');
    else
        allSpectraDenom = [];
    end

    % Pre-allocate
    S_out            = zeros(size(S_in));
    r_PO4_CO3        = zeros(1,size(S_in,2));
    r_PO4_AmideIII   = r_PO4_CO3;
    r_PO4_CH2        = r_PO4_CO3;
    r_PO4_AmideI     = r_PO4_CO3;
    r_CO3_AmideIII   = r_PO4_CO3;

    %–––––––––––––––––––––––––– Main loop –––––––––––––––––––––––––––––––––
    for i = 1:size(S_in,2)
        ss = S_in(:,i);

        % Masks
        PO4_mask      = wn >= region.PO4(1)      & wn <= region.PO4(2);
        CO3_mask      = wn >= region.CO3(1)      & wn <= region.CO3(2);
        CH2_mask      = wn >= region.CH2(1)      & wn <= region.CH2(2);
        AmideI_mask   = wn >= region.AmideI(1)   & wn <= region.AmideI(2);
        AmideIII_mask = wn >= region.AmideIII(1) & wn <= region.AmideIII(2);

        % Values for NORMALIZATION.
        %   peak         : raw regional maximum relative to zero.
        %   peakBaseline : regional maximum relative to a straight line
        %                  connecting the two endpoints of the region.
        %   area         : regional area after endpoint-baseline subtraction.
        getVal = @(mask) localNormValue(wn, ss, mask, method);

        PO4_val      = getVal(PO4_mask);
        CO3_val      = getVal(CO3_mask);
        CH2_val      = getVal(CH2_mask);
        AmideI_val   = getVal(AmideI_mask);
        AmideIII_val = getVal(AmideIII_mask);

        %–– AREA-ONLY values for RATIOS (always use area) ––
        PO4_area      = mean(ss(PO4_mask))*nnz(PO4_mask) - mean([ss(find(PO4_mask,1,'first')),      ss(find(PO4_mask,1,'last'))])      * nnz(PO4_mask);
        CO3_area      = mean(ss(CO3_mask))*nnz(CO3_mask) - mean([ss(find(CO3_mask,1,'first')),      ss(find(CO3_mask,1,'last'))])      * nnz(CO3_mask);
        CH2_area      = mean(ss(CH2_mask))*nnz(CH2_mask) - mean([ss(find(CH2_mask,1,'first')),      ss(find(CH2_mask,1,'last'))])      * nnz(CH2_mask);
        AmideI_area   = mean(ss(AmideI_mask))*nnz(AmideI_mask) - mean([ss(find(AmideI_mask,1,'first')),   ss(find(AmideI_mask,1,'last'))])   * nnz(AmideI_mask);
        AmideIII_area = mean(ss(AmideIII_mask))*nnz(AmideIII_mask) - mean([ss(find(AmideIII_mask,1,'first')), ss(find(AmideIII_mask,1,'last'))]) * nnz(AmideIII_mask);

        %–– Ratios: ALWAYS area/area ––
        r_PO4_AmideI(i)   = PO4_area   / AmideI_area;
        %r_CO3_AmideIII(i) = (CO3_area + PO4_area)   / (AmideIII_area+CH2_area+AmideI_area);
        r_CO3_AmideIII(i) = CO3_area   / AmideIII_area;
        %r_CO3_AmideIII(i) = CH2_area   / AmideI_area;
        r_PO4_CO3(i)      = PO4_area   / CO3_area;
        r_PO4_CH2(i)      = PO4_area   / CH2_area;
        r_PO4_AmideIII(i) = PO4_area   / AmideIII_area;

        %–– Choose denominator for normalisation ––
        if useNoNormalization
            S_out(:,i) = ss;
            continue
        elseif useFullSpectrum && method == "area"
            denom = allSpectraDenom;
        elseif useFullSpectrum && method == "peak"
            denom = max(ss);
        elseif useFullSpectrum && method == "peakBaseline"
            valid = ~isnan(wn) & ~isnan(ss);
            denom = localNormValue(wn, ss, valid, method);
        else
            switch normRegion
                case 'PO4',       denom = PO4_val;
                case 'CO3',       denom = CO3_val;
                case 'CH2',       denom = CH2_val;
                case 'AmideI',    denom = AmideI_val;
                case 'AmideIII',  denom = AmideIII_val;
            end
        end

        % Avoid divide-by-zero
        if isnan(denom) || denom == 0
            warning('Spectrum %d: denominator for %s is zero – spectrum left unscaled.',i,normRegion);
            S_out(:,i) = ss;
        else
            S_out(:,i) = ss / denom;
        end
    end
end


function val = localNormValue(wn, ss, mask, method)
    idx = find(mask);
    if isempty(idx)
        val = NaN;
        return;
    end

    if method == "area"
        val = mean(ss(mask))*nnz(mask) - ...
            mean([ss(find(mask,1,'first')), ss(find(mask,1,'last'))])*nnz(mask);
    elseif method == "peakBaseline"
        xRegion = wn(idx);
        yRegion = ss(idx);
        [peakHeight, localPeakIdx] = max(yRegion);

        xLeft = xRegion(1);
        xRight = xRegion(end);
        yLeft = yRegion(1);
        yRight = yRegion(end);
        xPeak = xRegion(localPeakIdx);

        if xRight == xLeft
            baselineAtPeak = mean([yLeft, yRight]);
        else
            baselineAtPeak = yLeft + (yRight - yLeft) * ...
                ((xPeak - xLeft) / (xRight - xLeft));
        end

        val = peakHeight - baselineAtPeak;
    else
        val = max(ss(mask));
    end
end
