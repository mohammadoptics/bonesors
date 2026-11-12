function rgb = localColorSpecToRGB(colorSpec)
    if isnumeric(colorSpec) && numel(colorSpec) == 3
        rgb = double(colorSpec(:)).';
        rgb = max(min(rgb, 1), 0);
        return
    end

    switch lower(char(string(colorSpec)))
        case 'b'
            rgb = [0 0 1];
        case 'g'
            rgb = [0 1 0];
        case 'r'
            rgb = [1 0 0];
        case 'c'
            rgb = [0 1 1];
        case 'm'
            rgb = [1 0 1];
        case 'y'
            rgb = [1 1 0];
        case 'k'
            rgb = [0 0 0];
        case 'w'
            rgb = [1 1 1];
        otherwise
            try
                rgb = validatecolor(colorSpec);
            catch
                rgb = [0 0 0];
            end
    end
end

