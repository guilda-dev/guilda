function out = heaviside(x)
% Return the unit step of a scalar: 1 for x > 0, 0 otherwise.
    arguments (Input)
        x    % Scalar to test.
    end
    arguments (Output)
        out  % 1 for x > 0, 0 otherwise.
    end
    if x > 0
        out = 1;        
    else
        out = 0;
    end
end
