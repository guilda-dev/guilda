classdef SolverODE < auxiliary
% Solver of the time simulation (net.simulate).
%
% net.solver_ODE holds one. It holds no settings: net.simulate combines the TimeSimulation
% section of GUILDA.setting with the Name-Value options of the call and passes them to
% solve; neither the solver nor the settings file is changed. The network, the event time
% table and the trajectories of a run are local to solve, and the result is returned as a
% ResultODE. The DAE of the network is integrated phase by phase: a phase is a time
% interval in which the set of active disturbances (Scenario) does not change. Each phase
% is solved with the MATLAB ode object (Solver, Tolerance, AbsoluteTolerance, MaxStep,
% InitialStep, SeparateComplexParts).
%
% - Tolerance and AbsoluteTolerance are the RelativeTolerance and AbsoluteTolerance of ode
%   (RelTol and AbsTol of odeset).
% - MaxStep and InitialStep are set in the SolverOptions of the ode object when they are
%   not NaN; NaN keeps the default of the Solver. Other options of the solver are not
%   accepted.
% - `TimeLimit` is checked at each solver step. When it is exceeded, the simulation stops
%   at the time reached, and the result has flag = 0 ("stopped by TimeLimit").
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% sc = net.add_scenario("fault");
% sc.add_fault("B008", [1, 1.05]);
% result = net.simulate("fault", Solver="ode23t", Progress="none");  % this call only
% ```
%
% See also ResultODE, Scenario, PowerNetwork.simulate

    properties (SetAccess=private, Hidden) % Version
        Ver (1,1) double = 2.0                                                                                         % Version of this class.
    end

    methods
        function obj = SolverODE()
        % Create a time simulation solver (the settings are read at each run).
        %
        % A network creates its own (net.solver_ODE); net.reset_solver() replaces it with a
        % new one.
            arguments (Output)
                obj  % Time simulation solver.
            end
        end

        [result, flag, output] = solve(obj, net, time, c_events, sct_options)
    end

    methods (Static, Access=private)
        sct = build_index(net)
        [EM, RM, lv_FBorTC, x0, M0] = initial_condition(ctx, ph, x0, M0)
        sct_out = phase_result(ctx, ph, sct_sol)
        ctx = set_admittance(ctx, sv_open, l_force)
        o = set_equations(o, ctx, RM, EM, lg, Mass)
        g = solve_differential(f, dMd, lv_dif, lv_eqD)
        l = is_false_index_error(ctx, me)
        l = is_numerical_failure(me, o)
        [ctx, o] = use_dense(ctx, o, x0, RM, EM, lg, l_verbose, Mass)
        odeX = getODEFunction(ctx, t, x, RM, EM, lg)
        odeJac = getODEJacobian(ctx, t, x, RM, EM, lg)
        [x0, M0] = getNextPhase(ctx, x0, M0, RM, EM)
    end
end
