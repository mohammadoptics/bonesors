function tf = localIsPlottableSpectrumCombineMode(combineMode)
    mode = lower(string(combineMode));
    tf = any(mode == ["mean","add","sum","diff","ratio"]);
end

