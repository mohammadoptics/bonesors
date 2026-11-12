function [prediction, info] = fitReconstructionPLS(X, Y, Xtest, ncomp, algorithm, maxIter, tolerance)
%FITRECONSTRUCTIONPLS Centered PLS2; scaling belongs to the training fold.
% NIPALS follows sklearn PLSRegression(scale=false): mode A, regression
% deflation, unnormalized Y weights, squared X-weight convergence criterion.
% SIMPLS retains the former MATLAB reconstruction for reproducibility.
if nargin < 5, algorithm = "NIPALS"; end
if nargin < 6, maxIter = 5000; end
if nargin < 7, tolerance = 1e-6; end
validateattributes(X,{'double'},{'2d','finite','nonempty'});
validateattributes(Y,{'double'},{'2d','finite','nonempty'});
validateattributes(Xtest,{'double'},{'2d','finite'});
validateattributes(ncomp,{'numeric'},{'scalar','integer','positive','<=',min([size(X,1)-1,size(X,2),size(Y,2)])});
validateattributes(maxIter,{'numeric'},{'scalar','integer','positive'});
validateattributes(tolerance,{'numeric'},{'scalar','positive','finite'});
assert(size(X,1)==size(Y,1) && size(Xtest,2)==size(X,2), ...
    'MainGUI:ReconstructionData','PLS input dimensions do not match.');
algorithm = string(validatestring(algorithm,{'NIPALS','SIMPLS'}));
info = struct('algorithm',algorithm,'iterations',[],'maxIterations',maxIter, ...
    'tolerance',tolerance,'fittedComponents',ncomp);
if algorithm == "SIMPLS"
    [~,~,~,~,beta] = plsregress(X,Y,ncomp);
    prediction = [ones(size(Xtest,1),1) Xtest]*beta;
    return
end
xMean = mean(X,1); yMean = mean(Y,1);
A = X-xMean; B = Y-yMean;
W = zeros(size(X,2),ncomp); P = W;
Q = zeros(size(Y,2),ncomp);
machineEps = eps('double');
for component = 1:ncomp
    B(:,all(abs(B)<10*machineEps,1)) = 0;
    first = find(any(abs(B)>machineEps,1),1);
    if isempty(first)
        info.fittedComponents = component-1;
        break
    end
    u = B(:,first); oldW = 100;
    for iteration = 1:maxIter
        w = (A'*u)/(u'*u);
        w = w/(sqrt(w'*w)+machineEps);
        t = A*w;
        c = (B'*t)/(t'*t);
        u = (B*c)/(c'*c+machineEps);
        change = w-oldW;
        if change'*change < tolerance || size(Y,2)==1, break; end
        oldW = w;
    end
    if iteration == maxIter
        warning('MainGUI:PLSConvergence', ...
            'NIPALS reached %d iterations at component %d. Check convergence.',maxIter,component);
    end
    if any(~isfinite(w)) || any(~isfinite(c))
        error('MainGUI:PLSDegenerate','NIPALS encountered a degenerate component. Reduce the component count.');
    end
    [~,largest] = max(abs(w));
    w = w*sign(w(largest));
    t = A*w;
    p = (A'*t)/(t'*t);
    q = (B'*t)/(t'*t);
    A = A-t*p'; B = B-t*q';
    W(:,component) = w; P(:,component) = p; Q(:,component) = q;
    info.iterations(end+1) = iteration;
end
% scipy.linalg.pinv uses max(shape)*eps*smax (MATLAB's default differs).
crossLoadings = P'*W;
pinvTolerance = max(size(crossLoadings))*machineEps*norm(crossLoadings,2);
rotation = W*pinv(crossLoadings,pinvTolerance);
prediction = (Xtest-xMean)*(rotation*Q')+yMean;
end
