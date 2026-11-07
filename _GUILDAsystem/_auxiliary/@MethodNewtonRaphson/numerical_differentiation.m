function Jacobian = numerical_differentiation(obj, x, OBJFcn, del)
% Compute the Jacobian of OBJFcn at x by central differences.
    arguments (Input)
        obj       %#ok<INUSA>
        x         % Point at which to differentiate (column).
        OBJFcn    % Function to differentiate.
        del       % Step of the differences.
    end
    arguments (Output)
        Jacobian  % Jacobian of OBJFcn at x.
    end
    nx  = numel(x);
    Jacobian = cell2mat( arrayfun(@(ITER) ( OBJFcn(x+[zeros(ITER-1,1);del;zeros(nx-ITER,1)]) - ...
        OBJFcn(x-[zeros(ITER-1,1);del;zeros(nx-ITER,1)]) ) / 2 / del, 1:nx, 'UniformOutput', false) );
end
