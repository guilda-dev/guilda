classdef ResultLIN < ResultBase
% Result of get_sys.
%
% Holds the linear model of a layer at one point, as connected by SolverLIN.solve from the
% linear blocks of its model objects. For the network (output.s_layer "PowerNetwork") it is
% the unreduced linear DAE
%
% ```
% rm_E dx/dt = rm_Axx x + rm_Axv v + rm_Bx u
%          0 = rm_Avx x + rm_Avv v + rm_Bv u
% ```
%
% where x are the states, v = [Vre1; Vim1; Vre2; ...] the bus voltages and u the inputs,
% all in the order of the variable map tab_variable (= net.get_variable_map() at the time
% of the analysis). The algebraic equations are the current balance of each bus,
% 0 = (Y v - I of the components), in the order of v. The values are deviations from the
% point rv_point. Y is the admittance matrix of the model, also at a point inside a fault.
% get_ss returns the model of a Type ("ODE": the bus voltages eliminated, or "DAE"),
% get_contribution the part of each element in the DAE, and plot_eigenvalue draws the
% eigenvalue map.
%
% The properties A, B, C, D, E, StateName, InputName and OutputName hold one linear model
% (E dx/dt = A x + B u, y = C x + D u) with the names of the states, inputs and outputs, as
% in a state-space (ss) object, without the Control System Toolbox: get_ss(Type) with the
% Input, Output and Coordinate of get_sys. They are computed from the DAE when read, and
% Type chooses the model: its default is the Type of get_sys, and setting it (res.Type =
% "DAE") switches all of them. They are empty when get_ss stops (flag false, or "ODE" with
% a singular Avv); get_ss gives the reason.
%
% A result of comp.get_sys, bus.get_sys, con.get_sys or gc.get_sys (output.s_layer
% "Component", "Bus", "LocalController" or "GlobalController") holds the port model of the
% layer in A ... OutputName (see PowerSystemModel.get_sys), the point rv_point and the
% blocks rm_Axx, rm_Axv (the voltage inputs), rm_Bx (the other inputs of tab_variable)
% and rm_E. get_ss returns that model, and Type and Coordinate do not apply.
%
% - `tab_variable` has one row per variable with Index, Kind, Role, Owner, Name, Label, Bus
%   and Equilibrium: the leading rows x, Vre, Vim, u of the variable map of the layer (for
%   a controller: its x, the voltages and its uc), the order of rv_point.
% - `sct_model` holds the connected model (field sct_sys: the descriptor model over
%   [x; v] with its outputs, from SolverLIN.solve) and, for the network, the admittance
%   matrix, the bus voltages at the point and the names of the bus currents: used by the
%   coordinates of get_ss("DAE") and its Output option; sct_sys also holds the terms of
%   each element (sct_term) and their classes (tab_owner) for get_contribution. The
%   result holds computed values only; the network is not changed.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% [result, flag] = net.get_sys();
% eig(full(result.rm_Axx))          % Jacobian blocks of the unreduced DAE
% eig(result.A, result.E)           % model of result.Type (the Type of get_sys)
% result.Type = "DAE";              % A ... OutputName are now the DAE
% sct = result.get_ss("ODE", Format="struct");   % reduced model as a struct
% sys = result.get_ss("ODE");       % ss object (Control System Toolbox)
% sct_gen = result.get_contribution("component.generator.abstract");   % part of the generators in the DAE
% result.plot_eigenvalue();                    % eigenvalue map
% ```
%
% See also SolverLIN, ResultBase, PowerSystemModel.get_sys

    properties (SetAccess=private) % Result
        tab_variable table = table()           % Variable map at the time of the analysis: the order of the rows and columns of the Jacobian blocks.
        rv_point (:,1) double = zeros(0,1)     % Point of the linearization in the order of tab_variable (the equilibrium when output.l_equilibrium is true).
        rm_Axx double = zeros(0,0)             % d(dx/dt)/dx: Jacobian of the state equations with respect to the states.
        rm_Axv double = zeros(0,0)             % d(dx/dt)/dv: Jacobian of the state equations with respect to the bus voltages.
        rm_Bx double = zeros(0,0)              % d(dx/dt)/du: Jacobian of the state equations with respect to the inputs.
        rm_Avx double = zeros(0,0)             % Jacobian of the bus current balance (Y v - I) with respect to the states.
        rm_Avv double = zeros(0,0)             % Jacobian of the bus current balance (Y v - I) with respect to the bus voltages: Y minus the component terms.
        rm_Bv double = zeros(0,0)              % Jacobian of the bus current balance (Y v - I) with respect to the inputs.
        rm_E double = zeros(0,0)               % Mass matrix of the state equations (the algebraic equations have none).
    end
    properties % Model
        Type (1,1) string {mustBeMember(Type, ["ODE","DAE"])} = "ODE"   % Model of A ... OutputName: "ODE" (the bus voltages eliminated) or "DAE" (the connected model). Default: the Type of get_sys.
    end
    properties (Dependent, SetAccess=private) % Model
        A          % State matrix of the model (E dx/dt = A x + B u, y = C x + D u): get_ss(Type) with the Input and Output of get_sys. <@Type> double
        B          % Input matrix of the model. <@Type> double
        C          % Output matrix of the model. <@Type> double
        D          % Feedthrough matrix of the model. <@Type> double
        E          % Mass matrix of the model (singular for "DAE"). <@Type> double
        StateName  % Names of the states of the model. <@Type> string (:,1)
        InputName  % Names of the inputs of the model. <@Type> string (:,1)
        OutputName % Names of the outputs of the model (the network has none by default). <@Type> string (:,1)
    end
    properties (SetAccess=private, Hidden) % Model data
        sct_model struct = struct()            % Data of get_ss: the connected model sct_sys and, for the network, cm_Y, cv_V, sv_I (see the class help).
    end
    properties (Access=private, Hidden) % Cache
        sct_cache struct = struct()            % Models of A ... OutputName by Type, computed when first read.
    end

    methods
        function obj = ResultLIN(net, solver, options, flag, output, elapsed, tab_variable, rv_point, sct_sys)
        % Create a linearization result.
        %
        % Stores the computed values of a linearization: the connected model sct_sys of
        % SolverLIN.solve and its blocks.
            arguments (Input)
                net                 = [] % Analysed network; see ResultBase.
                solver              = "SolverLIN" % Solver object or its class name; see ResultBase.
                options      struct = struct() % Effective settings; see ResultBase.
                flag                = false % Success or convergence flag; see ResultBase.
                output       struct = struct() % Solver details (n_x, n_v, s_layer, ...); see ResultBase.
                elapsed             = NaN % [s] Elapsed time or tic value; see ResultBase.
                tab_variable table  = table() % Variable map (leading rows).
                rv_point     double = zeros(0,1) % Point in the order of tab_variable.
                sct_sys      struct = struct() % Connected model (SolverLIN.solve); for the network also cm_Y, cv_V, sv_I.
            end
            arguments (Output)
                obj % The result object.
            end
            obj@ResultBase(net, solver, options, flag, output, elapsed);
            if isfield(options, "Type")
                obj.Type = options.Type;
            end
            obj.tab_variable = tab_variable;
            obj.rv_point     = rv_point(:);
            obj.sct_model    = struct("sct_sys", sct_sys);
            if ~isfield(sct_sys, "A")
                return
            end
            n_x = size(sct_sys.A,1) - sct_sys.n_v;
            ix  = 1:n_x;
            iv  = n_x+1:size(sct_sys.A,1);
            if sct_sys.n_v > 0
                obj.rm_Axx = sct_sys.A(ix,ix);  obj.rm_Axv = sct_sys.A(ix,iv);  obj.rm_Bx = sct_sys.B(ix,:);
                obj.rm_Avx = sct_sys.A(iv,ix);  obj.rm_Avv = sct_sys.A(iv,iv);  obj.rm_Bv = sct_sys.B(iv,:);
                obj.rm_E   = sct_sys.E(ix,ix);
            else
                % a port model: the voltage inputs and the other inputs of tab_variable
                lv_V = ismember(sct_sys.InputName, tab_variable.Label(tab_variable.Kind == "Vre" | tab_variable.Kind == "Vim"));
                lv_u = ismember(sct_sys.InputName, tab_variable.Label) & ~lv_V;
                obj.rm_Axx = sct_sys.A;
                obj.rm_Axv = sct_sys.B(:,lv_V);
                obj.rm_Bx  = sct_sys.B(:,lv_u);
                obj.rm_E   = sct_sys.E;
            end
            for s = ["cm_Y","cv_V","sv_I"]
                if isfield(sct_sys, s)
                    obj.sct_model.(s) = sct_sys.(s);
                end
            end
        end

        function v = get.A(obj)
            obj.sct_cache = fill_cache(obj, obj.sct_cache);
            v = obj.sct_cache.(obj.Type).A;
        end
        function v = get.B(obj)
            obj.sct_cache = fill_cache(obj, obj.sct_cache);
            v = obj.sct_cache.(obj.Type).B;
        end
        function v = get.C(obj)
            obj.sct_cache = fill_cache(obj, obj.sct_cache);
            v = obj.sct_cache.(obj.Type).C;
        end
        function v = get.D(obj)
            obj.sct_cache = fill_cache(obj, obj.sct_cache);
            v = obj.sct_cache.(obj.Type).D;
        end
        function v = get.E(obj)
            obj.sct_cache = fill_cache(obj, obj.sct_cache);
            v = obj.sct_cache.(obj.Type).E;
        end
        function v = get.StateName(obj)
            obj.sct_cache = fill_cache(obj, obj.sct_cache);
            v = obj.sct_cache.(obj.Type).StateName;
        end
        function v = get.InputName(obj)
            obj.sct_cache = fill_cache(obj, obj.sct_cache);
            v = obj.sct_cache.(obj.Type).InputName;
        end
        function v = get.OutputName(obj)
            obj.sct_cache = fill_cache(obj, obj.sct_cache);
            v = obj.sct_cache.(obj.Type).OutputName;
        end

        sys = get_ss(obj, Type, opt)
        [sct_value, sct_mask] = get_contribution(obj, target)
        fig = plot_eigenvalue(obj, opt)
    end
end


function sct_cache = fill_cache(obj, sct_cache)
% Adds the model of obj.Type to the cache: get_ss(Type) with the Input and Output of
% get_sys, or an empty model when get_ss stops (flag false: get_ss gives the reason)
    s_type = obj.Type;
    if isfield(sct_cache, s_type)
        return
    end
    c_nv = cell(1,0);
    for str = ["Input","Output"]
        if isfield(obj.options, str)
            c_nv = [c_nv, {str, obj.options.(str)}]; %#ok<AGROW>
        end
    end
    sct = struct("A", zeros(0,0), "B", zeros(0,0), "C", zeros(0,0), "D", zeros(0,0), "E", zeros(0,0), ...
                 "StateName", strings(0,1), "InputName", strings(0,1), "OutputName", strings(0,1));
    if ~isempty(obj.tab_variable) && isfield(obj.sct_model, "sct_sys") && isfield(obj.sct_model.sct_sys, "A")
        try
            sct = obj.get_ss(s_type, c_nv{:}, Format="struct");
        catch
            % no model of this Type: get_ss gives the reason
        end
    end
    sct_cache.(s_type) = sct;
end

