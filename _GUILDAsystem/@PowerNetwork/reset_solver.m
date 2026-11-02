function reset_solver(obj)
% Restore the default analysis solvers of the network.
%
% Replaces solver_PF, solver_OPF, solver_CPF, solver_ODE and solver_LIN with new
% solver objects, which discards the stored defaults changed on them.
%
% See also PFCsolver, OPFsolver, CPFsolver, ODEsolver, LTIsolver
    obj.solver_PF  = PFCsolver();
    obj.solver_OPF = OPFsolver();
    obj.solver_CPF = CPFsolver();
    obj.solver_ODE = ODEsolver();
    obj.solver_LIN = LTIsolver();
end