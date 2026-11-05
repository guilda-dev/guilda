function [ctx, o] = use_dense(ctx, o, x0, RM, EM, lg, l_verbose, Mass)
% Solve the current phase again and the next phases with dense matrices.
    arguments (Input)
        ctx        % Context of the run.
        o          % MATLAB ode object of the run.
        x0         % Initial value of the phase.
        RM         % Reduction matrix of the phase.
        EM         % Expansion matrix of the phase.
        lg         % True for the entries of the full state vector that are solved.
        l_verbose  % True to print a message.
        Mass       % Mass matrix of the phase.
    end
    arguments (Output)
        ctx  % Context with dense matrices.
        o    % ode object with dense equations.
    end
    ctx.l_sparse = false;
    ctx.Ymat     = full(ctx.Ymat);
    ctx.absYmat  = full(ctx.absYmat);
    o.InitialValue = x0;
    o.InitialSlope = zeros(0,1);
    o = SolverODE.set_equations(o, ctx, RM, EM, lg, full(Mass));
    lastwarn("");
    if l_verbose
        disp("The solver rejected the sparse matrices: using dense matrices.")
    end
end
