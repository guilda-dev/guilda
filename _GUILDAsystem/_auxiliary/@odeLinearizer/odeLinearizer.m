classdef odeLinearizer < auxiliary
% <@Desc>
% Solver of the linearization. net.solver_LIN holds one; its properties are the stored
% defaults of net.linearize and net.get_sys and are kept between runs. Name-Value options
% of a call override them for that call only (see OptionMap and get_options). The solver
% holds settings only: the network is passed to solve and the linear model is returned
% as a LinearizationResult.
% <@Role> Class Category
% <@Constructor>
% obj = odeLinearizer()
% The v3 form odeLinearizer(net, NonUnit, Algorithm=...) is removed (it stops with
% GUILDA:Deprecated:OdeLinearizerConstructor); use net.linearize.

    properties (Access=public)
        % <@Desc> Reduction used by result.get_ss() and net.get_sys when no Algorithm is
        % given: "Kron" (eliminate the bus voltages from the DAE), "Feedback" (connect the
        % bus models in I-to-V form through the admittance matrix) or "DAE" (keep the
        % voltages as algebraic states, descriptor form with a singular E).
        % <@Role> Settings
        % <@Type> string
        % <@Size> 1x1
        Algorithm (1,1) string {mustBeMember(Algorithm, ["Kron","Feedback","DAE"])} = "Feedback"

        % <@Desc> Indices of buses (in a_Bus) treated as non-unit buses by "Feedback": they
        % are eliminated with the network and their components are left out. A bus without
        % components is always a non-unit bus. The buses are not changed.
        % <@Role> Settings
        % <@Type> double
        % <@Size> 1xn
        NonUnit (1,:) double {mustBeInteger, mustBePositive} = zeros(1,0)

        % <@Desc> Point of the linearization. [] for the equilibrium (set by
        % net.initialize); a vector of the values in the order of the variable map of the
        % analysed layer (net / bus / comp .get_variable_map()); or {sim, t}: the state of
        % the simulation result sim at time t. The model is not changed.
        % <@Role> Settings
        % <@Type> [] | double vector | cell {simulation result, t}
        % <@Size> -
        Point = []
    end

    properties (Constant)
        % <@Desc> Name-Value options of net.linearize / net.get_sys and the solver property
        % each one sets (input of tools.resolve_options).
        % <@Role> Settings
        % <@Type> struct
        % <@Size> 1x1
        OptionMap = struct( ...
            "Algorithm", "Algorithm", ...
            "NonUnit",   "NonUnit", ...
            "Point",     "Point")
    end

    methods
        function obj = odeLinearizer(varargin)
            v3_linearizer_constructor(varargin);        % COMPAT(v3)
        end

        function set.Point(obj, val)
            odeLinearizer.check_point(val);
            obj.Point = val;
        end

        function s_options = get_options(obj, nv)
        % <@Desc>
        % Effective settings of one run: the stored settings of the solver with the
        % Name-Value overrides of the call applied. The solver itself is not changed.
        % A name that is not in OptionMap stops with GUILDA:resolve_options:UnknownName;
        % an invalid value stops with the validation error of the option.
        % <@Role> Settings
        % <@Summary> Stored settings + call-time overrides, as a struct.
        % <@Signatures>
        % [
        %   "s_options = get_options(obj)",
        %   "s_options = get_options(obj, {Name1, Value1, ...})"
        % ]
        % <@Parameters>
        % [
        %   {"Name": "obj", "Type": "odeLinearizer", "Description": "Solver holding the defaults (net.solver_LIN).", "Required": true, "Default": "-"},
        %   {"Name": "nv", "Type": "cell", "Description": "Name-Value overrides: Algorithm, NonUnit, Point.", "Required": false, "Default": "{}"}
        % ]
        % <@Returns>
        % [
        %   {"Name": "s_options", "Type": "struct", "Description": "Fields Algorithm, NonUnit, Point."}
        % ]
            arguments
                obj
                nv (1,:) cell = {}
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
