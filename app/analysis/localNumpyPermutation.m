function permutation = localNumpyPermutation(n, seed)
%LOCALNUMPYPERMUTATION NumPy legacy RandomState(seed).permutation(n), 1-based.
% MT19937 integer seed initialization, tempered uint32 output, and masked
% rejection sampling in Fisher-Yates order. Does not touch MATLAB's RNG.
% Unlike randperm, this matches sklearn KFold(shuffle=true, random_state=seed).
validateattributes(n,{'numeric'},{'scalar','integer','nonnegative','finite'});
validateattributes(seed,{'numeric'},{'scalar','integer','nonnegative','<=',2^32-1});
state = zeros(1,624,'uint32'); state(1) = uint32(seed);
mask32 = uint64(4294967295);
for j=2:624
    prev = bitxor(state(j-1),bitshift(state(j-1),-30));
    state(j) = uint32(bitand(uint64(1812433253)*uint64(prev)+uint64(j-1),mask32));
end
index = 625;
permutation = 1:n;
for i=n-1:-1:1
    mask = uint32(2^ceil(log2(i+1))-1);
    draw = bitand(nextUInt(),mask);
    while double(draw)>i, draw = bitand(nextUInt(),mask); end
    j = double(draw)+1;
    temp = permutation(i+1); permutation(i+1)=permutation(j); permutation(j)=temp;
end
    function value = nextUInt()
        if index>624
            for k=1:624
                next = mod(k,624)+1;
                bits = bitor(bitand(state(k),uint32(2147483648)), ...
                    bitand(state(next),uint32(2147483647)));
                value = bitxor(state(mod(k-1+397,624)+1),bitshift(bits,-1));
                if bitand(bits,uint32(1)), value=bitxor(value,uint32(2567483615)); end
                state(k)=value;
            end
            index=1;
        end
        value=state(index); index=index+1;
        value=bitxor(value,bitshift(value,-11));
        value=bitxor(value,bitand(bitshift(value,7),uint32(2636928640)));
        value=bitxor(value,bitand(bitshift(value,15),uint32(4022730752)));
        value=bitxor(value,bitshift(value,-18));
    end
end
