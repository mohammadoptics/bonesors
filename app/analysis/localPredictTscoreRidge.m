function [yPred,tuning] = localPredictTscoreRidge(X,y,cadIDs,settings,blockSizes)
%LOCALPREDICTTSCORERIDGE Outer donor LOCO; inner donor K-fold alpha selection.
% Objective: sum((y-X*b-intercept).^2) + alpha*sum(b.^2).
% Intercept is NOT penalized. This is sklearn Ridge's alpha convention,
% not a mean-loss penalty. Scaling uses sample SD and training-only imputation.
if nargin<5, blockSizes=[]; end
cadIDs=string(cadIDs(:)); y=y(:); X=double(X);
if size(X,1)~=numel(y) || numel(cadIDs)~=numel(y) || any(~isfinite(y))
    error('MainGUI:RidgeData','Ridge requires aligned rows and finite outcomes.');
end
ids=unique(cadIDs,'stable'); % sklearn KFold uses the input donor order.
if numel(ids)<4, error('MainGUI:RidgeData','Ridge needs at least four donors.'); end
alphas=settings.ridgeAlphaGrid(:).';
validateattributes(alphas,{'numeric'},{'vector','positive','finite','nonempty'});
K=min(settings.ridgeInnerFolds,numel(ids)-1);
validateattributes(K,{'numeric'},{'scalar','integer','>=',2});
yPred=nan(size(y));
tuning=repmat(struct('CadaverID',"",'Alpha',NaN,'InnerRMSE',NaN, ...
    'InnerFolds',K,'InnerCadaverIDs',strings(0,1),'InnerFold',[], ...
    'CandidateAlpha',alphas,'CandidateMSE',[]),numel(ids),1);
for outer=1:numel(ids)
    test=cadIDs==ids(outer); train=~test;
    trainIDs=ids(ids~=ids(outer));
    order=localNumpyPermutation(numel(trainIDs),settings.randomSeed);
    sizes=repmat(floor(numel(trainIDs)/K),1,K);
    sizes(1:mod(numel(trainIDs),K))=sizes(1:mod(numel(trainIDs),K))+1;
    folds=zeros(numel(trainIDs),1); cursor=0;
    for k=1:K
        folds(order(cursor+(1:sizes(k))))=k; cursor=cursor+sizes(k);
    end
    loss=zeros(size(alphas));
    for k=1:K
        val=train & ismember(cadIDs,trainIDs(folds==k)); fit=train & ~val;
        [A,Q]=prepare(X(fit,:),X(val,:));
        for j=1:numel(alphas)
            prediction=solve(A,y(fit),Q,alphas(j));
            loss(j)=loss(j)+sum((prediction-y(val)).^2);
        end
    end
    [~,best]=min(loss);
    [A,Q]=prepare(X(train,:),X(test,:));
    yPred(test)=solve(A,y(train),Q,alphas(best));
    tuning(outer).CadaverID=ids(outer); tuning(outer).Alpha=alphas(best);
    tuning(outer).InnerRMSE=sqrt(loss(best)/sum(train));
    tuning(outer).InnerCadaverIDs=trainIDs; tuning(outer).InnerFold=folds;
    tuning(outer).CandidateMSE=loss/sum(train);
end
    function [A,Q]=prepare(A,Q)
        for col=1:size(A,2)
            values=A(isfinite(A(:,col)),col);
            if isempty(values), med=0; else, med=median(values); end
            A(~isfinite(A(:,col)),col)=med; Q(~isfinite(Q(:,col)),col)=med;
        end
        if settings.standardizePredictors
            [A,Q]=localStandardizeTrainTest(A,Q,blockSizes);
        elseif ~isempty(blockSizes)
            error('MainGUI:TscoreBlockScaling','Block scaling requires standardization.');
        end
    end
end

function pred=solve(A,y,Q,alpha)
mu=mean(A,1); ym=mean(y); A=A-mu; Q=Q-mu;
% SVD remains stable for strongly correlated ratios and BMI/weight.
[U,S,V]=svd(A,'econ'); s=diag(S);
beta=V(:,1:numel(s))*((s./(s.^2+alpha)).*(U(:,1:numel(s))'*(y-ym)));
pred=Q*beta+ym;
end
