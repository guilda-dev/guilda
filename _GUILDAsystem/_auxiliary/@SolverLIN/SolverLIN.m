classdef SolverLIN < auxiliary
% Connector of the linearization (get_sys of every layer).
%
% get_sys (PowerSystemModel.get_sys) collects the linear blocks of the model objects of a
% layer (get_linear_block) and its port (get_linear_port); solve connects them along the
% variable map and returns the descriptor model, from which get_sys makes a ResultLIN.
% The connector reads only its arguments: no network and no model object. It holds no
% settings: the defaults of the options of get_sys (Method, Coordinate, PlotFcn) are the
% Linearization section of GUILDA.setting (GUILDA.config("Linearization")), and an option
% of a call overrides them for that call only.
%
% - `Method` is the reduction of the network: "Kron" (eliminate the bus voltages from the
%   DAE) or "DAE" (keep the voltages as algebraic states, descriptor form with a
%   singular E).
% - `Point` (given in a call only, not a setting) is [] for the equilibrium (set by
%   net.initialize, the default); a vector of the values in the order of the variables of
%   the layer (point_vector); or {sim, t}: the state of the simulation result sim at time t
%   (sim.get_point(t); at a phase boundary the value after the event, or
%   {sim, t, "before"} for the value before it). It sets the variables only: the
%   admittance matrix stays the one of the model, also at a time inside a fault. The model
%   is not changed.
% - `Coordinate` sets the bus variables of get_ss("DAE") and get_sys with Method "DAE":
%   "theta&rho" (angle and log magnitude), "theta&V" (angle and magnitude) or "Vre&Vim"
%   (real and imaginary parts). "Kron" does not use it.
% - `PlotFcn` (live display) is "none" only (tools.check_plotfcn);
%   result.plot_eigenvalue() draws the eigenvalue map.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% res = net.get_sys();                 % Method of GUILDA.setting ("Kron")
% res = net.get_sys(Method="DAE");     % this call only
% ```
%
% See also ResultLIN, PowerSystemModel.get_sys

    methods
        function obj = SolverLIN(varargin)
        % Create a linearization connector.
        %
        % A network creates its own (net.solver_LIN); net.reset_solver() replaces it with a
        % new one. The v3 form SolverLIN(net, NonUnit, Algorithm=...) is removed: any
        % argument stops with GUILDA:v3_linearizer_constructor:OdeLinearizerConstructor (use net.get_sys).
            arguments (Input, Repeating)
                varargin  % Arguments of the removed v3 form (any of them stops with an error).
            end
            arguments (Output)
                obj  % Linearization connector.
            end
            v3_linearizer_constructor(varargin);        % COMPAT(v3)
        end

        [sct_sys, output] = solve(obj, c_block, tab, tab_connection, sct_port)
    end

    methods (Static, Hidden)
        [rv_point, l_equilibrium] = point_vector(layer, Point)
        check_point(Point)
    end
end
