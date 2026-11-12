function [yPred,tuning,foldRanks] = localPredictTscoreMatchedKFold(X,y,cadIDs,settings,maxRank,blockSizes)
% Matched comparison protocol: outer donor LOCO, shuffled inner donor K-fold.
% Matches compare_models.py: input-order NumPy shuffle, pooled validation SSE,
% fold-only median imputation/sample SD/block scaling, no response scaling.
% Does not read saved predictions or outcomes from any reference run.
if nargin<6, blockSizes=[]; end
X=double(X); y=y(:); cadIDs=string(cadIDs(:));
ids=unique(cadIDs,'stable'); model=lower(string(settings.tscoreModel));
if size(X,1)~=numel(y) || numel(cadIDs)~=numel(y) || any(~isfinite(y)) || numel(ids)<4
    error('MainGUI:MatchedData','Matched nested CV needs aligned finite outcomes and at least four donors.');
end
if ~any(model==["pls" "svr"])
    error('MainGUI:MatchedModel','Matched nested CV supports PLS and RBF-SVR.');
end
if model=="svr"
    [yPred,tuning]=localPredictMatchedSVRPython(X,y,cadIDs,settings,blockSizes);
    foldRanks=nan(size(y)); return
end
K=min(settings.matchedInnerFolds,numel(ids)-1);
validateattributes(K,{'numeric'},{'scalar','integer','>=',2});
candidates=(1:min(maxRank,size(X,2)))';
if ~isempty(settings.fixedPLSRank), candidates=settings.fixedPLSRank; end
yPred=nan(size(y)); foldRanks=nan(size(y));
tuning=repmat(struct('CadaverID',"",'Rank',NaN,'BoxConstraint',NaN, ...
    'Epsilon',NaN,'KernelScale',NaN,'InnerRMSE',NaN,'InnerFolds',K, ...
    'InnerCadaverIDs',strings(0,1),'InnerFold',[],'Candidates',candidates, ...
    'CandidateMSE',[]),numel(ids),1);
for outer=1:numel(ids)
    test=cadIDs==ids(outer); train=~test; trainIDs=ids(ids~=ids(outer));
    order=localNumpyPermutation(numel(trainIDs),settings.randomSeed);
    sizes=repmat(floor(numel(trainIDs)/K),1,K);
    sizes(1:mod(numel(trainIDs),K))=sizes(1:mod(numel(trainIDs),K))+1;
    folds=zeros(numel(trainIDs),1); cursor=0;
    for k=1:K
        folds(order(cursor+(1:sizes(k))))=k; cursor=cursor+sizes(k);
    end
    loss=zeros(size(candidates,1),1);
    for k=1:K
        val=train & ismember(cadIDs,trainIDs(folds==k)); fit=train & ~val;
        [A,Q]=prepare(X(fit,:),X(val,:));
        for j=1:size(candidates,1)
            if candidates(j)>size(A,1)-1
                loss(j)=Inf; continue
            end
            p=solve(A,y(fit),Q,candidates(j,:));
            loss(j)=loss(j)+sum((p-y(val)).^2);
        end
    end
    [bestLoss,best]=min(loss);
    if ~isfinite(bestLoss), error('MainGUI:MatchedCandidates','No feasible candidate in inner validation.'); end
    [A,Q]=prepare(X(train,:),X(test,:));
    yPred(test)=solve(A,y(train),Q,candidates(best,:));
    tuning(outer).CadaverID=ids(outer); tuning(outer).InnerRMSE=sqrt(bestLoss/sum(train));
    tuning(outer).InnerCadaverIDs=trainIDs; tuning(outer).InnerFold=folds;
    tuning(outer).CandidateMSE=loss/sum(train);
    tuning(outer).Rank=candidates(best); foldRanks(test)=candidates(best);
    fprintf('%s matched inner %d-fold: outer donor %d/%d (%s)\n',upper(model),K,outer,numel(ids),ids(outer));
    drawnow limitrate
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
    function p=solve(A,b,Q,param)
        [~,~,~,~,beta]=plsregress(A,b,param(1));
        p=[ones(size(Q,1),1) Q]*beta;
    end
end
