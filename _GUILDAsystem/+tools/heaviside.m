function out = heaviside(x)
% Return the unit step of a scalar: 1 for x > 0, 0 otherwise.
    if x > 0
        out = 1;        
    else
        out = 0;
    end
end