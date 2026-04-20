function [dx,I,y] = dynamics( x, V, u, parameter,opt)
    dx = zeros(0, 1);
    Iabs = u(1);
    Iarg = u(2);
    I = Iabs*exp(1j*Iarg);
    y = [];
end