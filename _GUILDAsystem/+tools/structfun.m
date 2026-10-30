function out = structfun(func,data)
% Apply a function to each element of a struct array and concatenate the results.
%
% Inputs: `func` (function handle) and `data` (struct array). The results are concatenated
% horizontally for a row and vertically otherwise.

    ndata = numel(data);
    out   = cell(size(data));
    for i = 1:ndata
        out{i} = func(data(i));
    end

    if find(size(data)==1,1) == 1
        out = horzcat(out{:});
    else
        out = vertcat(out{:});
    end

end