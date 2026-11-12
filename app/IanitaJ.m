function [spec,components] = IanitaJ(wavelength,spec,order,c1,c2,iter,addlb,convergepercent,peakremovalflag,noisefac,noise)
% Improved automated fluorescence subtraction from Raman spectra
%
% [fitspec,components] = IanitaJ(wavelength,spec,order,c1,c2,iter)
% fitspec: spectrum after fluorescence background subtraction;
% wavelength: wavelength values of measured spectrum; spec: input spectrum;
% order: polynomial order for the fit; c1, c2: fitting region;
% iter: maximum number of iterations
%
% [fitspec,components] = IanitaJ(wavelength,spec,order,c1,c2,iter,addlb)
% addlb: additional spectra to include in the basis set for the fit, use []
% for no additional spectra
%
% [fitspec,components] = IanitaJ(wavelength,spec,order,c1,c2,iter,addlb,convergepercent,peakremovalflag,noisefac,noise)
% convergepercent: stops iterating if percent change in standard deviation
% of residual is less than converge percent; peakremovalflag: set to 1 in
% order to attempt removal of Raman peaks before fitting; noisefac: number
% of standard deviations in noise to permit below zero intensity
% noise: noise at each pixel (same dimension as spec), if noise is not
% passed, IanitaJ makes an estimate of the noise based upon the
% standard deviation of the residual of the fit
%
% Defaults: addlb = []; convergepercent = 5E-4; peakremovalflag = 0; noisefac = 0;
%
% Modeled after 'Automated Autofluorescence Background Subtraction Algorithm
% for Biomedical Raman Spectroscopy' by Zhao et al.
% JRM 11/19/10
    
    % Number of standard deviations in noise to permit below zero intensity
    if exist('noisefac','var') == 0
        noisefac = 0; % noisefac = 0 performs a conventional ANITA fit
    end
    if exist('peakremovalflag','var')==0
        peakremovalflag = 0; % peakremovalflag = 1 attempts to remove Raman peaks before fitting
    end
    % Convergence Condition
    if exist('convergepercent','var') == 0
        convergepercent = 5E-4;
    end
    if exist('noise','var') == 1
        noiseflag = 1;
    else
        noiseflag = 0;
    end
    
    % Create Polynomials to Use in Basis
    px = (wavelength-mean(wavelength))./std(wavelength);
    % Initialize polynomial matrix
    polyb = zeros(size(spec,1),order+1);
    % Values range from 1 to 2^order
    for j=0:1:order
        polyb(:,j+1)=px.^j;
    end
    
    % Add additional Basis Vectors
    if exist('addlb','var') == 1
        basis = [polyb addlb];
    else
        basis = polyb;
    end
    
    % For each spectrum
    for jkl = 1:size(spec,2)
        putin = spec(c1:c2,jkl); reducedbasis = basis(c1:c2,:);
        
        % Perform the Ordinary Least Squares Fit Between c1 and c2
        [~,putout,~,residual] = OLSJ(putin,reducedbasis);
        DEV = std(residual);
        
        % Raman peak removal
        if noiseflag == 1
            noisecorrection = noise(c1:c2,jkl);
            if peakremovalflag == 1
                noremoval = (putin<(putout+3.*noisecorrection));
                noisecorrection = noisecorrection(noremoval);
            end
        elseif peakremovalflag == 1
            noremoval = (putin<(putout+3.*DEV));
        end
        if peakremovalflag == 1
            reducedbasis = reducedbasis(noremoval,:);
            putin = putin(noremoval);
            if isreal(putin) == 0
                pause;
            end
        end
        
        % 1st iteration
        % Perform the Ordinary Least Squares Fit Between c1 and c2
        [c,~,components,residual] = OLSJ(putin,reducedbasis);
        DEVlast = std(residual);
        
        if noiseflag ~= 1 % Estimate noise as DEV
            noisecorrection = DEVlast;
        end
        
        % Reasign fit values that would result in negative spectral
        % intensity
        residualcorrection = residual-noisefac.*noisecorrection;
        cutoff = (residualcorrection+abs(residualcorrection))./2;
        
        putin = putin - cutoff;
        
        for ijk = 2:iter % For each iteration
            % Perform the Ordinary Least Squares Fit Between c1 and c2
            [c,~,components,residual] = OLSJ(putin,reducedbasis);
            
            % Calculate the standard deviation of the residual
            DEV = std(residual);
            
            differ = abs((DEV-DEVlast)./DEV);
            % If the difference is small break from the loop
            if differ < convergepercent
                break
            end
            DEVlast = DEV;
            
            if noiseflag ~= 1 % Estimate noise as DEV
                noisecorrection = DEV;
            end
            
            % Reasign fit values that would result in negative spectral
            % intensity
            residualcorrection = residual-noisefac.*noisecorrection;
            cutoff = (residualcorrection+abs(residualcorrection))./2;
            
            putin = putin - cutoff;
        end % of for each iteration
        
        % Subtract estimated fluorescence lineshape
        spec(:,jkl) = spec(:,jkl) - basis*c;
    end % of for each spectrum
end

function [c,OLSfit,components,residual] = OLSJ(spec,basis)
% function [c,OLSfit,components,residual] = OLSJ(spec,basis)
% Perform an ordinary least squares fit to a set of spectra with a matrix
% composed of the basis spectra for the fit.  The fit coefficients are
% returned in the matrix c.  OLSfit is the fit to each spectrum, and
% components is a cell array with each cell containing a matrix of the
% component spectra that make up the total fit.  All spectra are defined as
% COLUMN vectors.

    % Not sure why I can't use basis instead of bT' below, but I get
    % strange results when fitting small spectral regions if basis is used
    bT = basis';
    c = (bT*(bT'))\(bT*spec); % The fit coefficients
    % c = basis\spec;
    OLSfit = basis*c; % The computed fit
    components = cell(1,size(c,2)); % Components that make up the fit
    for ijk = 1:size(c,2)
        components{ijk} = basis*diag(c(:,ijk));
    end
    residual = spec-OLSfit; % Residual
end