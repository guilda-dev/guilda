function out = l2norm(t, y)
% Compute the L2 norm of time signals by trapezoidal integration.
%
% Inputs: `t` (time, column) and `y` (signals, one column per signal). Output: the square
% root of the sum over the signals of the integral of y.^2.
    out = sqrt(sum(trapz(t, y.^2), 2));
end