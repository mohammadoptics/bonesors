function [S_out,r_PO4_CO3,r_PO4_AmideIII,r_PO4_CH2,r_PO4_AmideI,r_CO3_AmideIII] = normalize_PO4 (wn,S_in)


    for i=1:size(S_in,2)

        ss = S_in(:,i);
        % Define the range for the PO4 region and CH2
        PO4_start = 930;
        PO4_end = 990;

        CO3_start = 1050;
        CO3_end = 1100;

        CH2_start = 1360;
        CH2_end = 1500;

        AmideI_start = 1550;
        AmideI_end = 1700;

        AmideIII_start = 1214;
        AmideIII_end = 1334;


        % Create a logical mask for the PO4 region
        PO4_mask = (wn >= PO4_start) & (wn <= PO4_end);
        CH2_mask = (wn >= CH2_start) & (wn <= CH2_end);
        CO3_mask = (wn >= CO3_start) & (wn <= CO3_end);
        AmideI_mask = (wn >= AmideI_start) & (wn <= AmideI_end);
        AmideIII_mask = (wn >= AmideIII_start) & (wn <= AmideIII_end);


        % Find the indices of non-zero (true) elements in the regions
        PO4_indices = find(PO4_mask);
        PO4_Nbins = nnz(PO4_mask);

        CO3_indices = find(CO3_mask);
        CO3_Nbins = nnz(CO3_mask);

        CH2_indices = find(CH2_mask);
        CH2_Nbins = nnz(CH2_mask);

        AmideI_indices = find(AmideI_mask);
        AmideI_Nbins = nnz(AmideI_mask);

        AmideIII_indices = find(AmideIII_mask);
        AmideIII_Nbins = nnz(AmideIII_mask);


        % Get the starting and ending indices of the Amide I region
        PO4_start_index = PO4_indices(1);
        PO4_end_index = PO4_indices(end);

        CO3_start_index = CO3_indices(1);
        CO3_end_index = CO3_indices(end);

        CH2_start_index = CH2_indices (1);
        CH2_end_index = CH2_indices (end);

        AmideI_start_index = AmideI_indices(1);
        AmideI_end_index = AmideI_indices(end);

        AmideIII_start_index = AmideIII_indices(1);
        AmideIII_end_index = AmideIII_indices(end);



        PO4_Area = mean(ss(PO4_mask))*PO4_Nbins-mean([ss(PO4_start_index),ss(PO4_end_index)])*PO4_Nbins;

        CO3_Area = mean(ss(CO3_mask))*CO3_Nbins-mean([ss(CO3_start_index),ss(CO3_end_index)])*CO3_Nbins;

        CH2_Area = mean(ss(CH2_mask)) * CH2_Nbins - mean([ss(CH2_start_index), ss(CH2_end_index)]) * CH2_Nbins;

        AmideI_Area = mean(ss(AmideI_mask)) * AmideI_Nbins - mean([ss(AmideI_start_index), ss(AmideI_end_index)]) * AmideI_Nbins;


        AmideIII_Area = mean(ss(AmideIII_mask)) * AmideIII_Nbins - mean([ss(AmideIII_start_index), ss(AmideIII_end_index)]) * AmideIII_Nbins;

        r_PO4_AmideI (i) = PO4_Area / AmideI_Area;
        r_CO3_AmideIII (i) = CO3_Area / AmideIII_Area;
        r_PO4_CO3(i) = PO4_Area / CO3_Area;
        r_PO4_CH2 (i) = PO4_Area / CH2_Area;
        r_PO4_AmideIII (i) = PO4_Area / AmideIII_Area;

        %spectrum normalized to PO4 region
        %S_out (:,i) = ss / PO4_Area;

        % Normalize the spectrum to PO4 peak
        PO4_peak = max(ss(PO4_mask));
        % normalizedSpectrum = spectrumData / areaPhosphate;
        S_out (:,i) = ss / PO4_peak;

        % % Normalize the spectrum to AmideI peak
        % AmideI_peak = max(ss(AmideI_mask));
        % % normalizedSpectrum = spectrumData / areaPhosphate;
        % S_out (:,i) = ss / AmideI_peak;

    end

end