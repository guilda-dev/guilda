classdef SolverLIN < auxiliary
% Connector of the linearization (get_sys of every layer).
%
% get_sys (PowerSystemModel.get_sys) collects the linear blocks of the model objects of a
% layer (get_linear_matrix) and builds the port of the layer from its variable map; solve
% connects them along the variable map and returns the connected descriptor model (the DAE), from which get_sys
% makes a ResultLIN. reduce eliminates the algebraic variables of a DAE (the bus voltages
% of the network): the model of Type "ODE". The connector reads only its arguments: no
% network and no model object. It holds no settings: the defaults of the options of
% get_sys (Type, Port, PlotFcn) are the ApproximateLinearization section of GUILDA.setting
% (GUILDA.config("ApproximateLinearization")), and an option of a call overrides them for that call
% only.
%
% - `Type` is the model of the network: "ODE" (the DAE with the bus voltages eliminated,
%   SolverLIN.reduce) or "DAE" (the connected model, with the voltages as algebraic
%   variables and a singular E).
% - The point (the first argument of get_sys, not a setting) is [] for the equilibrium
%   (set by net.initialize, the default); a vector of the values in the order of the
%   leading rows of layer.get_variable_map() (x, Vre, Vim, u, uc; for a controller x, Vre, Vim,
%   uc; point_vector), every value used as given; or {sim, t}: the state of the simulation result sim at time t
%   (sim.get_point(t); at a phase boundary the value after the event, or
%   {sim, t, "before"} for the value before it). {sim, rv_t} with several times, or a
%   matrix with one point per column, gives one time section per time or column
%   (ResultLIN.rv_t, ResultLIN.Index). It sets the variables only: the
%   admittance matrix stays the one of the model, also at a time inside a fault. The model
%   is not changed.
% - `Port` sets how each bus is written in the DAE (get_ss("DAE") and get_sys with Type
%   "DAE"): the bus variables v and the current balance w. "PI": v = [theta, V],
%   w = [P, Q/V]; "PQ": v = [theta, log V], w = [P, Q]; "I": v = [Vre, Vim],
%   w = [-Iim, Ire]. The computation stays in Vre, Vim; the port changes the result only.
%   "ODE" does not use it.
% - `Form` is the view of the matrices (ResultLIN.Form): "descriptor", "absorbed" or
%   "hessian", the energy-function form that get_sys builds from get_hessian of the
%   devices and solve assembles with the network part (network, Port "PI" or "PQ").
% - `PlotFcn` (live display) is "none" only (tools.check_plotfcn);
%   result.plot_eigenvalue() draws the eigenvalue map.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% res = net.get_sys();                 % Type of GUILDA.setting ("ODE")
% res = net.get_sys(Type="DAE");       % this call only
% ```
%
% See also ResultLIN, PowerSystemModel.get_sys

    methods
        function obj = SolverLIN()
        % Create a linearization connector.
        %
        % A network creates its own (net.solver_LIN); net.reset_solver() replaces it with a
        % new one. It takes no arguments.
            arguments (Output)
                obj  % Linearization connector.
            end
        end

        [sct_sys, output] = solve(obj, c_block, tab, tab_connection, sct_port)
    end

    methods (Static)
        sct_ode = reduce(sct_dae, iv_algebraic)
    end

    methods (Static, Hidden)
        [rm_point, rv_t, l_equilibrium] = point_vector(layer, point)
        check_point(point)
    end
end
