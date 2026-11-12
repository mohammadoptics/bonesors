function [XtrainZ, XtestZ] = localStandardizeTrainTest(Xtrain, Xtest, blockSizes)
    % Optional blocks are weighted AFTER training-only column standardization.
    % Do not autoscale columns again downstream: that would undo the weights.
    if nargin < 3, blockSizes = []; end
    mu = mean(Xtrain, 1);
    sigma = std(Xtrain, 0, 1);
    sigma(~isfinite(sigma) | sigma == 0) = 1;

    XtrainZ = (Xtrain - mu) ./ sigma;
    XtestZ  = (Xtest  - mu) ./ sigma;
    if ~isempty(blockSizes)
        if ~isvector(blockSizes) || any(~isfinite(blockSizes)) || ...
                any(blockSizes < 1 | blockSizes ~= fix(blockSizes)) || ...
                sum(blockSizes) ~= size(Xtrain,2)
            error('MainGUI:TscoreBlockSizes', ...
                'Positive integer block sizes must cover every predictor column.');
        end
        weights = repelem(1 ./ sqrt(blockSizes(:).'), blockSizes(:).');
        XtrainZ = XtrainZ .* weights;
        XtestZ = XtestZ .* weights;
    end
end
