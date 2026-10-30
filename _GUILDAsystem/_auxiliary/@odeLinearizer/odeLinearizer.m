classdef odeLinearizer < auxiliary
% Solver of the linearization (net.linearize, net.get_sys).
%
% net.solver_LIN holds one; its properties are the stored defaults of net.linearize and
% net.get_sys and are kept between runs. Name-Value options of a call override them for
% that call only (see OptionMap and get_options). The solver holds settings only: the
% network is passed to solve and the linear model is returned as a LinearizationResult.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% net.solver_LIN.Algorithm = "Kron";              % stored default, kept between runs
% sys = net.get_sys();                            % uses "Kron"
% result = net.linearize(NonUnit=[7 9], Algorithm="Feedback");   % this call only
% ```
%
% See also LinearizationResult, PowerNetwork.linearize, PowerNetwork.get_sys

    properties (Access=public) % Settings
        % Reduction used by result.get_ss() and net.get_sys when no Algorithm is given.
        % "Kron" (eliminate the bus voltages from the DAE), "Feedback" (connect the bus models in
        % I-to-V form through the admittance matrix) or "DAE" (keep the voltages as algebraic
        % states, descriptor form with a singular E).
        Algorithm (1,1) string {mustBeMember(Algorithm, ["Kron","Feedback","DAE"])} = "Feedback"

        % Indices of buses (in a_Bus) treated as non-unit buses by "Feedback".
        % They are eliminated with the network and their components are left out. A bus without components is always a non-unit bus. The buses are not changed.
        NonUnit (1,:) double {mustBeInteger, mustBePositive} = zeros(1,0)

        % Point of the linearization.
        % [] for the equilibrium (set by net.initialize); a vector of the values in the order of
        % the variable map of the analysed layer (net / bus / comp .get_variable_map()); or {sim,
        % t}: the state of the simulation result sim at time t. The model is not changed.
        % <@Type> [] | double vector | cell {simulation result, t}
        Point = []
    end

    properties (Constant) % Settings
        % Name-Value options of net.linearize / net.get_sys and the solver property each one sets.
        % Input of tools.resolve_options.
        % <@Type> struct
        OptionMap = struct( ...
            "Algorithm", "Algorithm", ...
            "NonUnit",   "NonUnit", ...
            "Point",     "Point")
    end

    methods
        function obj = odeLinearizer(varargin)
        % Create a linearization solver with the default settings.
        %
        % A network creates its own (net.solver_LIN); net.reset_solver() replaces it with a
        % new one. The v3 form odeLinearizer(net, NonUnit, Algorithm=...) is removed: any
        % argument stops with GUILDA:Deprecated:OdeLinearizerConstructor (use net.linearize).
            v3_linearizer_constructor(varargin);        % COMPAT(v3)
        end

        function set.Point(obj, val)
            odeLinearizer.check_point(val);
            obj.Point = val;
        end

        function s_options = get_options(obj, nv)
        % Get the effective settings of one run as a struct.
        %
        % The stored settings of the solver with the
        % Name-Value overrides of the call applied. The solver itself is not changed.
        % A name that is not in OptionMap stops with GUILDA:resolve_options:UnknownName;
        % an invalid value stops with the validation error of the option.
            arguments
                obj % Solver holding the defaults (net.solver_LIN).
                nv (1,:) cell = {} % Name-Value overrides: Algorithm, NonUnit, Point.
            end
            arguments (Output)
                s_options % Fields Algorithm, NonUnit, Point.
            end
            s_options = tools.resolve_options(obj, odeLinearizer.OptionMap, nv);
            validate_options(nv{:});
            s_options.Algorithm = string(s_options.Algorithm);
            s_options.NonUnit   = reshape(double(s_options.NonUnit), 1, []);
            odeLinearizer.check_point(s_options.Point);
        end

        [result, flag, output] = solve(obj, net, s_options)
    end

    methods (Static, Hidden)
        [rv_point, l_equilibrium] = point_vector(layer, Point)
        check_point(Point)
    end
end


function validate_options(opt)
% Value checks of the Name-Value options (names are already checked by resolve_options)
    arguments
        opt.Algorithm (1,1) string {mustBeMember(opt.Algorithm, ["Kron","Feedback","DAE"])}
        opt.NonUnit   (1,:) double {mustBeInteger, mustBePositive}
        opt.Point
    end
end
