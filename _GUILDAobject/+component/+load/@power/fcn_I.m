function I = fcn_I(obj, t, x, V, I, u, para) %#ok
    PQ = [1,1j]*u;
    Vi = [1,1j]*V;
    I = conj(PQ/Vi);
end