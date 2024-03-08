function out = l2norm(t, y)
    out = sqrt(sum(trapz(t, y.^2), 2));
end