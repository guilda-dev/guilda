function reset_solver(obj)
% Restore the default analysis solvers of the network.
%
% Replaces solver_PF, solver_OPF, solver_CPF, solver_ODE and solver_LIN with new
% solver objects, which discards the stored defaults changed on them.
%
% See also SolverPF, SolverOPF, SolverCPF, SolverODE, SolverLIN
    obj.solver_PF  = SolverPF();
    obj.solver_OPF = SolverOPF();
    obj.solver_CPF = SolverCPF();
    obj.solver_ODE = SolverODE();
    obj.solver_LIN = SolverLIN();
end