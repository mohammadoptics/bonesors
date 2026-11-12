    % ======================================================================
function [rmse, r] = evalMetrics(pred, truth)
    % pred  – N × M  double
    % truth – N × M  double
    % returns:
    %   rmse  – N×1  root-mean-sq-error
    %   r     – N×1  Pearson correlation
    diff2 = (pred - truth).^2;
    rmse  = sqrt( mean( diff2 , 2) );           % per-spectrum RMSE
    r     = zeros(size(rmse));
    for i = 1:size(pred,1)
        r(i) = corr(pred(i,:).', truth(i,:).'); % .' makes them columns
    end
end