function Jacobian = numerical_differentiation(obj, x, OBJFcn, del)
% Compute the Jacobian of OBJFcn at x by central differences (tools.fd_jacobian).
    arguments (Input)
        obj       %#ok<INUSA>
        x         % Point at which to differentiate (column).
        OBJFcn    % Function to differentiate.
        del       % Step of the differences.
    end
    arguments (Output)
        Jacobian  % Jacobian of OBJFcn at x.
    end
    Jacobian = tools.fd_jacobian(OBJFcn, x, Step=del);
end
