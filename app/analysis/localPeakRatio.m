function r = localPeakRatio(wn, spec, numeratorBand, denominatorBand)
    numPeak = localBandMax(wn, spec, numeratorBand);
    denPeak = localBandMax(wn, spec, denominatorBand);
    if ~isfinite(numPeak) || ~isfinite(denPeak) || denPeak == 0
        r = NaN;
    else
        r = numPeak / denPeak;
    end
end

