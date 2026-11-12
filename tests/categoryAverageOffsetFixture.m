function [records,groups,s] = categoryAverageOffsetFixture(columns)
% Synthetic spectra used only for regression and rendering checks.
wn=(750:2:1740).'; cats={'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
records=struct('CadaverID',{},'Category',{},'Tag',{},'Spectrum',{},'Wavenumber',{});
for i=1:9
    M=zeros(numel(wn),3);
    for k=1:3
        M(:,k)=.03+exp(-((wn-960)/12).^2)+(.1+.02*i)*exp(-((wn-1070)/16).^2) ...
            +(.03+.01*i+.025*k)*exp(-((wn-1260)/24).^2) ...
            +(.09+.02*i+.04*k)*exp(-((wn-1450)/22).^2)+(.03+.01*i)*exp(-((wn-1660)/18).^2);
    end
    records(i)=struct('CadaverID',sprintf('DEMO%d',i),'Category',cats{ceil(i/3)}, ...
        'Tag','D3P1_MM00','Spectrum',M(:,columns),'Wavenumber',wn);
end
predicted=records;
for i=1:9, predicted(i).Spectrum=records(i).Spectrum.*(1+.015*i*sin(wn/37)); end
groups(1)=struct('Tissue',"E",'Records',records);
groups(2)=struct('Tissue',"P",'Records',predicted);
s=analysisDefaultSettings(); s.feature.spectrumCombineMode="separate";
s.feature.normalizationRegion="PO4"; s.feature.normalizationMethod="peak";
end
