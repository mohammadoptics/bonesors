function jitter = localDeterministicJitter(indexValue, width)
    jitter = width * sin(indexValue * 12.9898);
end

