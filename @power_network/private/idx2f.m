function f = idx2f(fault_time, idx_fault)
if isempty(fault_time)
    f = @(t) [];
else
    if ~iscell(fault_time)
        f = @(t) select_value((fault_time(1)<=t && t<fault_time(2)), idx_fault, []);
    else
        fs = cellfun(@idx2f, fault_time, idx_fault, 'UniformOutput', false);
        f = @(t) f_tmp(t, fs);
    end
end
end

function idx = f_tmp(t, fs)
idx = [];
for itr = 1:numel(fs)
    idx = [idx; fs{itr}(t)]; %#ok
end

idx = unique(idx);
end

function out = select_value(isA, A, B)
if isA
    out = A;
else
    out = B;
end
end