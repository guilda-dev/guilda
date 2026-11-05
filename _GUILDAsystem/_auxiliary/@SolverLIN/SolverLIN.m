classdef SolverLIN < auxiliary
% Solver of the linearization (net.linearize, net.get_sys).
%
% net.solver_LIN holds one; its properties are the stored defaults of net.linearize and
% net.get_sys and are kept between runs. Name-Value options of a call override them for
% that call only (see OptionMap and get_options). The solver holds settings only: the
% network is passed to solve and the linear model is returned as a ResultLIN.
%
% - `Algorithm` is the reduction used when no Algorithm is given: "Kron" (eliminate the bus
%   voltages from the DAE), "Feedback" (connect the bus models in I-to-V form through the
%   admittance matrix) or "DAE" (keep the voltages as algebraic states, descriptor form
%   with a singular E).
% - `Point` is [] for the equilibrium (set by net.initialize); a vector of the values in
%   the order of the variable map of the analysed layer (net / bus / comp
%   .get_variable_map()); or {sim, t}: the state of the simulation result sim at time t
%   (sim.get_point(t), including the states of the controllers; at a phase boundary the
%   value after the event, or {sim, t, "before"} for the value before it). It sets the
%   variables only: the admittance matrix stays the one of the model, also at a time
%   inside a fault. The model is not changed.
% - `Coordinate` sets the bus variables of get_ss("DAE") and net.get_sys with Algorithm
%   "DAE": "theta&rho" (angle and log magnitude), "theta&V" (angle and magnitude) or
%   "Vre&Vim" (real and imaginary parts). "Kron" and "Feedback" do not use it.
% - `OptionMap` is the input of tools.resolve_options.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% net.solver_LIN.Algorithm = "Kron";              % stored default, kept between runs
% sys = net.get_sys();                            % uses "Kron"
% result = net.linearize(Algorithm="Feedback");   % this call only
% ```
%
% See also ResultLIN, PowerNetwork.linearize, PowerNetwork.get_sys

    properties (Access=public) % Settings
        Algorithm (1,1) string {mustBeMember(Algorithm, ["Kron","Feedback","DAE"])} = "Feedback"  % Reduction of result.get_ss() and net.get_sys: "Kron", "Feedback" or "DAE" (see the class help).
        Point = []  % Point of the linearization: [] (equilibrium), a vector in variable-map order, or {sim, t} (see the class help). <@Type> [] | double vector | cell
        Coordinate (1,1) string {mustBeMember(Coordinate, ["theta&V","theta&rho","Vre&Vim"])} = "theta&rho"  % Bus variables of the "DAE" reduction: "theta&rho", "theta&V" or "Vre&Vim" (see the class help).
    end

    properties (Hidden) % Compatibility
        NonUnit (1,:) double {mustBeInteger, mustBePositive} = zeros(1,0)  % COMPAT(v3) retired (v3_solver_nonunit)
    end

    properties (Constant) % Settings
        OptionMap = struct( ...
            "Algorithm", "Algorithm", ...
            "Point",     "Point", ...
            "Coordinate", "Coordinate")  % Name-Value options of net.linearize / net.get_sys and the property each one sets. <@Type> struct
    end

    methods
        function obj = SolverLIN(varargin)
        % Create a linearization solver with the default settings.
        %
        % A network creates its own (net.solver_LIN); net.reset_solver() replaces it with a
        % new one. The v3 form SolverLIN(net, NonUnit, Algorithm=...) is removed: any
        % argument stops with GUILDA:v3_linearizer_constructor:OdeLinearizerConstructor (use net.linearize).
            arguments (Input, Repeating)
                varargin  % Arguments of the removed v3 form (any of them stops with an error).
            end
            arguments (Output)
                obj  % Linearization solver with the default settings.
            end
            v3_linearizer_constructor(varargin);        % COMPAT(v3)
        end

        function set.NonUnit(obj, val), obj.NonUnit = v3_solver_nonunit(val); end           % COMPAT(v3)

        function set.Point(obj, val)
            SolverLIN.check_point(val);
            obj.Point = val;
        end

        sct_options = get_options(obj, nv)
        [result, flag, output] = solve(obj, net, sct_options)
    end

    methods (Static, Hidden)
        [rv_point, l_equilibrium] = point_vector(layer, Point)
        check_point(Point)
    end
end
