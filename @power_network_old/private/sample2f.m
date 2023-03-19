function f = sample2f(t, u)
if isempty(u) || size(u, 2)==0
    f = @(t) [];
else
    if size(u, 1) ~= numel(t) && size(u, 2) == numel(t)
        u = u';
    end
    f = @(T) u(find(t<=T, 1, 'last'),:)';
end
end
