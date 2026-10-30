function reset_solver(obj)
% Restore the default analysis solvers of the network.
%
% Replaces solver_PF, solver_OPF, solver_CPF, solver_ODE and solver_LIN with new
% solver objects, which discards the stored defaults changed on them.
%
% See also PowerFlowCalculation, OptimalPowerFlow, ContinuationPowerFlow, odeSimulator, odeLinearizer
    obj.solver_PF  = PowerFlowCalculation();
    obj.solver_OPF = OptimalPowerFlow();
    obj.solver_CPF = ContinuationPowerFlow();
    obj.solver_ODE = odeSimulator();
    obj.solver_LIN = odeLinearizer();
end