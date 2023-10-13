function out = structfun(func,data)

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