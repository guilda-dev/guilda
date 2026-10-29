function reset_solver(obj)
    obj.solver_PF  = PowerFlowCalculation();
    obj.solver_OPF = OptimalPowerFlow();
    obj.solver_CPF = ContinuationPowerFlow();
    obj.solver_ODE = odeSimulator();
    obj.solver_LIN = odeLinearizer();
end