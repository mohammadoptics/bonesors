function row = stitchIntact(Tmat, nCols)
% Tmat  – 499×3 matrix (intact spectrum)
% nCols – 1 | 2 | 3
%
%  • 1 → *only* spectrum-3  (6 mm)          → col 3
%  • 2 → spectrum-2 & 3     (3 mm & 6 mm)   → cols 2-3
%  • 3 → all three spectra  (0 mm 3 mm 6 mm)→ cols 1-3
%
% returns a row-vector 1 × (nCols*499)

    switch nCols
        case 1, useCols = 3;        % 6 mm only
        case 2, useCols = 2:3;      % 3 mm & 6 mm
        case 3, useCols = 1:3;      % 0 mm, 3 mm, 6 mm
        otherwise
            error('nIntactCols must be 1, 2 or 3');
    end
    if size(Tmat,2) < max(useCols)
        error('Cadaver %s: intact spectrum has only %d columns, requested %d.', ...
            cadID, size(Tmat,2), max(useCols));
    end
    row = reshape(Tmat(:,useCols), 1, []);   % row-stitch
end
