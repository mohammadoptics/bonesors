function xVals = localJitteredCategoryX(categoryIndex, n)
    if n <= 1
        xVals = categoryIndex;
    else
        xVals = categoryIndex + linspace(-0.08, 0.08, n).';
    end
end

