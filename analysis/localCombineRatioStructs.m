function out = localCombineRatioStructs(ratio1, ratio2, combineMode)
    fields = fieldnames(ratio1);
    out = struct();
    mode = lower(string(combineMode));

    for f = 1:numel(fields)
        fld = fields{f};
        v1 = ratio1.(fld);
        v2 = ratio2.(fld);

        switch mode
            case "ratiodiff"
                out.(fld) = v1 - v2;

            case "rationormdiff"
                out.(fld) = (v1 - v2) ./ (abs(v2) + eps);

            case "ratiosymnormdiff"
                out.(fld) = (v1 - v2) ./ ((abs(v2) + abs(v1)) ./ 2 + eps);

            otherwise
                error('Unknown ratio-level combine mode: %s', combineMode);
        end
    end
end
