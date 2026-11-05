function out = l2norm(t, y)
% Compute the L2 norm of time signals by trapezoidal integration.
    arguments (Input)
        t    % [s] Time, column vector.
        y    % Signals, one column per signal.
    end
    arguments (Output)
        out  % Square root of the sum over the signals of the integral of y.^2.
    end
    out = sqrt(sum(trapz(t, y.^2), 2));
end
