function renderAverageOffsets(outputFolder)
%RENDERAVERAGEOFFSETS Synthetic visual smoke test (not scientific results).
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root,fullfile(root,'analysis'));
if ~isfolder(outputFolder), mkdir(outputFolder); end
before=findall(groot,'Type','figure');
cleanup=onCleanup(@()delete(setdiff(findall(groot,'Type','figure'),before)));
GUI_Ver2;
f=findobj(groot,'Tag','MainGUI_Ver2'); f=f(1);
registry=analysisModeRegistry(); controls=f.UserData.controls;
set(controls.modePopup,'Value',find(strcmp({registry.value},'compareAverageSpectra')));
feval(controls.modePopup.Callback,controls.modePopup,[]);
assert(strcmp(controls.ratioRegionPopup.Visible,'on'));
set(controls.spectrumEdit,'String','1,2,3');
assert(contains(controls.spectrumEdit.TooltipString,'1 = 0 mm'));
set(controls.ratioRegionPopup,'Value',7);
feval(controls.ratioRegionPopup.Callback,controls.ratioRegionPopup,[]);
assert(strcmp(controls.ratioMethodPopup.Enable,'off'));
delete(f);

wn=(750:2:1740).'; categories={'NORMAL','OSTEOPENIA','OSTEOPOROSIS'};
actual=struct('CadaverID',{},'Category',{},'Tag',{},'Spectrum',{},'Wavenumber',{});
for i=1:9
    M=zeros(numel(wn),3);
    for k=1:3
        M(:,k)=.04+exp(-((wn-960)/12).^2)+(.13+.01*i)*exp(-((wn-1070)/16).^2) ...
            +(.08+.03*k)*exp(-((wn-1260)/24).^2)+(.12+.01*i+.025*k)*exp(-((wn-1450)/22).^2) ...
            +.08*exp(-((wn-1660)/18).^2);
    end
    actual(i)=struct('CadaverID',sprintf('DEMO%d',i),'Category',categories{ceil(i/3)}, ...
        'Tag','D3P1_MM00','Spectrum',M,'Wavenumber',wn);
end
predicted=actual;
for i=1:9, predicted(i).Spectrum=actual(i).Spectrum.*(1+.015*i*sin(wn/37)); end
s=analysisDefaultSettings(); s.feature.spectrumCombineMode="separate";
s.feature.normalizationRegion="PO4"; s.feature.normalizationMethod="peak";
s.compare.primaryLabel="Measured"; s.compare.secondaryLabel="Predicted";
localCompareAverageSpectra(actual,predicted,[1 2 3],{'D3P1_MM00'},s.feature,false,s.compare);
figs=setdiff(findall(groot,'Type','figure'),before);
for f=figs.'
    if contains(f.Name,'vertically offset categories'), name='average_three_offsets'; else, name='agreement_three_offsets'; end
    exportgraphics(f,fullfile(outputFolder,[name '.png']),'Resolution',120);
end
fprintf('GUI controls and three-offset preview verified. Synthetic preview saved.\n');
end
