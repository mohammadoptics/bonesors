function config = intactRatioPlsSvrPreset(config)
% Direct intact six-mm, all five ratios + age/weight/BMI; no reconstruction.
% Only sets options. Does not restrict donors or load reference predictions.
config=intactRatioRidgePreset(config);
config.tscore.models=["PLS" "SVR"];
config.tscore.validationProtocol="matchedKFold";
config.tscore.matchedInnerFolds=5;
config.tscore.maxPLSRank=8; config.tscore.fixedPLSRank=[];
config.tscore.svrOptimizationMode="nested";
config.tscore.svrBoxConstraintGrid=[.1 .3 1 3 10 30 100];
config.tscore.svrEpsilonGrid=[.01 .1 .3];
config.tscore.svrKernelScaleGrid=[.3 .7 1.5 3 10 30];
config.tscore.svrInnerFolds=5; config.tscore.svrMaxCandidates=126;
end
