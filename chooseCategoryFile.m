function chooseCategoryFile(fig,~)
    [f,p] = uigetfile('*.xls*','Select category sheet');
    if f==0, return, end

    ok = loadStatusExcel(fullfile(p,f),fig);   % ← drop "fig"
    if ok
        set(findobj(fig,'Tag','btnRatios'),'Enable','on');
    end
end


function ok = loadStatusExcel(fname,fig)
    ok = false;
    T  = readtable(fname,'VariableNamingRule','preserve','TextType','string');

    id  = upper(strip(T.('AGR-ID')));
    cat = strip(lower(T.('WHO Classification (Distal Radius; 1/3)')));

    % --- validate status strings ------------------------------------------
    allowed = ["normal","osteopenia","osteoporosis"];
    badRows = find(~ismember(cat,allowed));
    if ~isempty(badRows)
        msg = "Excel contains invalid WHO categories on rows: " + ...
              join(string(badRows+1),", ") + newline + ...
              "Allowed values are: Normal, Osteopenia, Osteoporosis.";
        errordlg(msg,'Invalid categories','modal');
        return
    end

    % --- build the map ----------------------------------------------------
    keys   = cellstr(id);
    values = cellstr(upper(cat));

    fig.UserData.statusMap      = containers.Map(keys, values);
    fig.UserData.statusFilename = fname;

    % ✅ NEW: store full table for later reporting
    fig.UserData.statusTable    = T;

    ok = true;
end



