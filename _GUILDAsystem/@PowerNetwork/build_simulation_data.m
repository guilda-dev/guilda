function [sct_dae, sct_event, rv_x0, tab_phase] = build_simulation_data(obj, s_scenario, time)
% (Hidden) Data of one run of simulate for SolverODE.solve: for tests and debugging.
%
% Gathers from the network everything the solver needs, so that SolverODE.solve reads no
% network, bus, branch, component, controller or scenario:
%   1. the checks before a run: stale models and edited inputs (net.initialize() needed)
%   2. the variable map and the connection map (get_variable_map)
%   3. the blocks of the components, local controllers and global controllers: their rows
%      in the map and their f_* function handles (closures with the parameters bound by
%      value), the equilibrium, the admittance matrix and the 2x2 matrix of each branch
%   4. the phases of the scenario (Scenario.compile): the disturbances as positions
%   5. the islands left by open branches
%   6. the initial value rv_x0: the equilibrium with the offsets and inputs of the first
%      phase
% The time is required, so that the time of a run is decided only by simulate (a test
% passes sc.Time).
%
% <@Examples>
% ```matlab
% [sct_dae, sct_event, rv_x0] = net.build_simulation_data("fault", [0, 10]);
% [sct_sol, flag, output] = net.solver_ODE.solve(sct_dae, sct_event, rv_x0, sct_options);
% ```
%
% See also PowerNetwork.simulate, SolverODE.solve, Scenario
    arguments (Input)
        obj
        s_scenario (1,1) string {simulateFcn_mustBeScenarioOf(obj, s_scenario)}   % Tag of the scenario.
        time (1,2) double {mustBeSimulationTime}   % [s] Simulation time [t0, tend].
    end
    arguments (Output)
        sct_dae   (1,1) struct   % Blocks, maps, admittance and equilibrium of the network.
        sct_event (:,1) struct   % One element per phase, the disturbances as positions.
        rv_x0     (:,1) double   % Initial value of the variable rows of sct_dae.tab_variable.
        tab_phase table          % output.phases: t1, t2, one logical column per disturbance.
    end
    simulateFcn_check(obj);
    sct_dae = simulateFcn_blocks(obj);

    sc = obj.a_Scenario{string(cellfun(@(s) s.s_tag, obj.a_Scenario, 'UniformOutput', false)) == s_scenario};
    [tab_phase, sct_event] = sc.compile(sct_dae, time);
    simulateFcn_check_islands(sct_dae, sct_event, tab_phase);

    % Initial value: the offsets and the inputs at t = 0 of the first phase
    rv_x0 = sct_dae.rv_equilibrium;
    ev = sct_event(1);
    rv_x0(ev.iv_offset) = rv_x0(ev.iv_offset) + ev.rv_offset;
    iv_in = zeros(0,1);
    for m = 1:size(ev.c_input, 1)
        iv_in = union(iv_in, ev.c_input{m,1});
    end
    rv_u = zeros(numel(rv_x0), 1);
    for m = 1:size(ev.c_input, 1)
        iv_row = ev.c_input{m,1};
        rv_u(iv_row) = rv_u(iv_row) + input_at_zero(ev.c_input(m,:));
    end
    rv_x0(iv_in) = rv_x0(iv_in) + rv_u(iv_in);
    sct_event(1).iv_offset = zeros(0,1);
    sct_event(1).rv_offset = zeros(0,1);
end


function rv_v = input_at_zero(c_in)
% Value at the start of the phase of one input event {iv_row, rv_t, rm_v, s_method}, as
% SolverODE evaluates it
    arguments (Input)
        c_in (1,4) cell  % One row of c_input.
    end
    arguments (Output)
        rv_v (:,1) double  % One value per input row.
    end
    [rv_t, rm_v, s_method] = c_in{2:4};
    if isscalar(rv_t)
        rv_v = rm_v(1,:).';
    elseif s_method == "zoh"
        rv_v = rm_v(max(1, nnz(rv_t <= 0)), :).';
    else
        sct_method = struct("foh", "linear", "spline", "spline");
        rv_v = zeros(size(rm_v,2), 1);
        for c = 1:size(rm_v,2)
            F = griddedInterpolant(rv_t, rm_v(:,c), sct_method.(s_method), "nearest");
            rv_v(c) = F(0);
        end
    end
end
