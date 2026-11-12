function updateSpectrumListbox(fig,~)

    selFiles   = get(fig.UserData.fileListBox   ,'Value');
    selFields  = get(fig.UserData.dataFieldListbox,'Value');
    origNames  = fig.UserData.dataFieldOriginalNames;

    if isempty(selFiles) || isempty(selFields)
        set(fig.UserData.spectrumListbox,'String',{'No Spectra'},'Value',[]);
        return
    end

    % ------------------------------------------------------------------
    % 1) examine the FIRST highlighted file & data-field
    % ------------------------------------------------------------------
    if isfield(fig.UserData, 'dataFieldFileIdx') && ...
            numel(fig.UserData.dataFieldFileIdx) >= selFields(1)
        firstFileIdx = fig.UserData.dataFieldFileIdx{selFields(1)};
    else
        firstFileIdx = selFiles(1);
    end
    originalDataField = origNames{selFields(1)};
    dStruct           = fig.UserData.data{firstFileIdx};
    data              = getFieldData(dStruct, originalDataField);   % 499×n

    % ------------------------------------------------------------------
    % 2) decide how many spectra and what label they should get
    % ------------------------------------------------------------------
    if isnumeric(data) && ismatrix(data)

        nSpec = max(1, size(data,2));        % a column-vector ⇒ 1

        % ── try to fetch "real" spectrum number stored by the NN ─────────
        specNumNN = [];
        if isfield(dStruct,'usedSpectra')
            specNumNN = dStruct.usedSpectra;                       % plain struct
        elseif isfield(dStruct,'process') && isfield(dStruct.process,'usedSpectra')
            specNumNN = dStruct.process.usedSpectra;               % inside process
        end

        if nSpec==1 && ~isempty(specNumNN)                         % predicted file
            labels = {sprintf('Spectrum %d', specNumNN)};
        else                                                       % normal case
            labels = arrayfun(@(k) sprintf('Spectrum %d',k), 1:nSpec,'uni',0);
        end

        set(fig.UserData.spectrumListbox,'String',labels,'Value',1);

    else                                                            % not numeric
        set(fig.UserData.spectrumListbox,'String',{'All Data'},'Value',1);
    end
end

