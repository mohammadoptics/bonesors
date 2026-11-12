%% ------------------------------------------------------------------------
%%  displayData –- plots raw *or* normalised spectra
%              doNormalise = false -> raw
%                            true  -> normalised
% ------------------------------------------------------------------------

function displayData(fig, doNormalise)
%--------------------------------------------------------------------------
% Plot raw or PO4-normalised spectra selected in «Select Spectra» listbox
% doNormalise = false  → raw
%               true   → PO4-normalised (area ratio shown in legend)
%--------------------------------------------------------------------------

    displayOptions = guiDefaultConfig().display;
    if isfield(fig.UserData, 'config') && isfield(fig.UserData.config, 'display')
        configured = fig.UserData.config.display;
        optionNames = fieldnames(configured);
        for optionIndex = 1:numel(optionNames)
            displayOptions.(optionNames{optionIndex}) = configured.(optionNames{optionIndex});
        end
    end

    % ---------- persistent colour wheel ----------------------------------
    persistent colourIdx
    if isempty(colourIdx),  colourIdx = 1;  end
    colours = lines(100);

    % ---------- user selections ------------------------------------------
    selFiles  = get(fig.UserData.fileListBox,     'Value');
    selFields = get(fig.UserData.dataFieldListbox,'Value');
    if isempty(selFiles) || isempty(selFields)
        errordlg('Select at least one file and one data field.','Selection error');
        return
    end

    selSpectra = get(fig.UserData.spectrumListbox,'Value');   % can be empty → all

    origFld  = fig.UserData.dataFieldOriginalNames;
    plotAx   = fig.UserData.ax;  hold(plotAx,'on');
    wnGlobal = [];                                        % remember one axis

    % =====================================================================
    for f = selFiles
        fileName = fig.UserData.fileNames{f};
        dStruct  = fig.UserData.data{f};

        %wn = extractWavenumber(dStruct);
        wn = dStruct.process.wavenum;
        if isempty(wn)
            warning('No wavenumber in %s – skipped.',fileName);
            continue
        end
        wnGlobal = wn;                                   % keep one valid axis

        listNames = {};
        if isfield(dStruct,'process') && isfield(dStruct.process,'list')
            listNames = dStruct.process.list;
        end

        for fld = selFields
            fieldPath = origFld{fld};
            data      = getFieldData(dStruct, fieldPath);      % 499 × n

            if isempty(data) || size(data,1) ~= numel(wn)
                continue
            end

            % Which spectra to take?
            if isempty(selSpectra)
                selIdx = 1:size(data,2);                      % all columns
            else
                selIdx = selSpectra(selSpectra <= size(data,2)); % guard length
            end

            % PO4 normalisation if requested
            if doNormalise
                % % [dataSel,~,~,r_PO4_AmideI] = normalize_PO4(wn, data(:,selIdx));
                [dataSel,r_PO4_CO3 , r_PO4_AmideIII , r_PO4_CH2 ,r_PO4_AmideI , r_CO3_AmideIII] = normalizeSpectra(wn , data(:,selIdx), ...
                    displayOptions.normalizationRegion, displayOptions.normalizationMethod);
                rChoice = r_PO4_AmideIII;
            else
                dataSel = data(:,selIdx);
                rChoice = nan(1,numel(selIdx));
            end

            sampleTag = mapFieldToProcessTag(fieldPath, listNames);

            % ==============================================================
            % Choose whether to plot spectra with vertical offsets or not
            % ==============================================================
            doOffsetPlot = displayOptions.applyVerticalOffset;

            % Decide offset spacing only if needed
            if doOffsetPlot
                selTraces = dataSel(:, 1:numel(selIdx));
                allRange  = max(selTraces(:)) - min(selTraces(:));
                if allRange == 0, allRange = 1; end
                yStep = 0.25 * allRange;    % tweak to control visual spacing
            else
                yStep = 0;                  % no offset applied
            end

            hold(plotAx, 'on')

            % -------- plot each chosen column ------------------------------
            for k = 1:numel(selIdx)
                col          = selIdx(k);
                trace        = dataSel(:,k);              % original data (unchanged)
                specLabel    = buildSpectrumLabel(dStruct,col);
                legendSuffix = '';
                if doNormalise
                    legendSuffix = sprintf(' (ratio %.3f)', rChoice(k));
                end

                % Add vertical offset only if enabled
                yoff = (k-1) * yStep * double(doOffsetPlot);

                plot(plotAx, wn, trace + yoff, ...
                    'DisplayName', sprintf('%s - %s%s', ...
                    sampleTag, specLabel, legendSuffix), ...
                    'Color', colours(colourIdx,:), 'LineWidth', 1.2);

                colourIdx = mod(colourIdx, size(colours,1)) + 1;
            end

            % % % -------- plot each chosen column ------------------------------
            % % for k = 1:numel(selIdx)
            % %     col          = selIdx(k);
            % %     trace        = dataSel(:,k);
            % %     specLabel    = buildSpectrumLabel(dStruct,col);
            % %     legendSuffix = '';
            % %     if doNormalise
            % %         legendSuffix = sprintf(' (ratio %.3f)', rChoice(k));
            % %     end
            % % 
            % % 
            % % 
            % % 
            % %     plot(plotAx, wn, trace,'DisplayName', sprintf('%s - %s%s', ...
            % %                                sampleTag, specLabel, legendSuffix), ...
            % %         'Color', colours(colourIdx,:), 'LineWidth', 1.2);
            % % 
            % %     colourIdx = mod(colourIdx, size(colours,1)) + 1;
            % % end
        end
    end

    % ---------- axes cosmetics -------------------------------------------
    xlabel(plotAx,'Wavenumber (cm^{-1})');
    if doNormalise
        ylabel(plotAx,'Normalised Intensity');
    else
        ylabel(plotAx,'Intensity');
    end
    legend(plotAx,'show','Interpreter','none','Location','best');
    if ~isempty(wnGlobal)
        xlim(plotAx,[wnGlobal(1) wnGlobal(end)]);
    end
end



% -------------------------------------------------------------------------
% helper: map 'process.spec{3}' → corresponding entry in process.list ------
function tag = mapFieldToProcessTag(fieldPath, listNames)
    tok = regexp(fieldPath,'process\.(?:anitaspec|spec)\{(\d+)\}','tokens','once');
    if ~isempty(tok)
        idx = str2double(tok{1});
        if idx<=numel(listNames)
            tag = listNames{idx};
            return
        end
    end
    tag = fieldPath;             % fallback
end
% helper: spectrum label ---------------------------------------------------
function label = buildSpectrumLabel(dStruct, colIdx)
    if isfield(dStruct,'usedSpectra')
        label = sprintf('Spectrum %d', dStruct.usedSpectra);
    elseif isfield(dStruct,'process') && isfield(dStruct.process,'usedSpectra')
        label = sprintf('Spectrum %d', dStruct.process.usedSpectra);
    else
        label = sprintf('Spectrum %d', colIdx);
    end
end
% -------------------------------------------------------------------------

function data = getFieldData(dataStruct, fieldPath)
    % Retrieve data from nested fields given a dot-separated path
    try
        data = dataStruct;
        tokens = regexp(fieldPath, '\.|\{|\}', 'split');
        for i = 1:length(tokens)
            token = tokens{i};
            if isempty(token)
                continue;
            elseif all(isstrprop(token, 'digit'))
                idx = str2double(token);
                data = data{idx};
            else
                data = data.(token);
            end
        end
    catch
        data = [];
        warning('Could not retrieve data for field path: %s', fieldPath);
    end
end

