function [dx,I,y] = dynamics( x, V, u, parameter,opt)
    dx = zeros(0, 1);
    PQ = u(1) + 1j*u(2);
    I = conj(PQ/V);
    y = [];
end