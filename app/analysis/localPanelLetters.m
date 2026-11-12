function panelLetters = localPanelLetters(nPanels)
    panelLetters = cell(1, nPanels);
    for k = 1:nPanels
        if k <= 26
            panelLetters{k} = char('A' + k - 1);
        else
            panelLetters{k} = sprintf('P%d', k);
        end
    end
end

