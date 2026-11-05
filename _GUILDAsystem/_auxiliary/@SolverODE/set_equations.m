function o = set_equations(o, ctx, RM, EM, lg, Mass)
% The mass matrix, right-hand side and Jacobian of a phase. They hold a copy of ctx.
% A mass matrix that is not diagonal (e.g. of a controller) is made the identity on the
% differential variables, by solving the differential equations with its block:
% M*x' = f becomes x'(d) = M(rd,d) \ f(rd), 0 = f(ra). The solutions are the same, and
% for a diagonal mass matrix the consistency step of the solver changes only the
% algebraic variables, while for a sparse one that is not diagonal it moves all of
% them (see CalculateInitialCondition).
    arguments (Input)
        o     % MATLAB ode object of the run.
        ctx   % Context of the run.
        RM    % Reduction matrix of the phase.
        EM    % Expansion matrix of the phase.
        lg    % True for the entries of the full state vector that are solved.
        Mass  % Mass matrix of the phase.
    end
    arguments (Output)
        o  % ode object with MassMatrix, ODEFcn and Jacobian set.
    end
    lv_dif = full(any(Mass ~= 0, 1)).';
    lv_eqD = full(any(Mass ~= 0, 2));
    if ~isdiag(Mass) && nnz(lv_dif) == nnz(lv_eqD)
        dMd = decomposition(Mass(lv_eqD, lv_dif));
        Mass = diag(double(lv_dif));
        if ctx.l_sparse
            Mass = sparse(Mass);
        end
        to_dif = @(f) SolverODE.solve_differential(f, dMd, lv_dif, lv_eqD);
        o.ODEFcn   = @(t,x) to_dif(SolverODE.getODEFunction(ctx,t,x,RM,EM,lg));
        o.Jacobian = @(t,x) to_dif(SolverODE.getODEJacobian(ctx,t,x,RM,EM,lg));
    else
        o.ODEFcn   = @(t,x) SolverODE.getODEFunction(ctx,t,x,RM,EM,lg);
        o.Jacobian = @(t,x) SolverODE.getODEJacobian(ctx,t,x,RM,EM,lg);
    end
    o.MassMatrix = Mass;
end
