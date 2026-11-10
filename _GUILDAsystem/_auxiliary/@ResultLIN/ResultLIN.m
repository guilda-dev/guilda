classdef ResultLIN < ResultBase
% Result of net.linearize.
%
% Holds the unreduced linear DAE of the network at one point,
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
% get_ss returns a reduced model (Kron / Feedback / DAE); Plot draws the eigenvalue map.
%
% The properties A, B, C, D, E, StateName, InputName and OutputName hold one linear model
% (E dx/dt = A x + B u, y = C x + D u) with the names of the states, inputs and outputs, as
% in a state-space (ss) object, without the Control System Toolbox. For net.linearize it is
% get_ss(options.Method) (all inputs and the default outputs); net.get_sys with Input or
% Output keeps them in options and selects them here. They are empty when get_ss stops for
% that Method (flag false, or "Feedback" without a bus to connect); get_ss gives the
% reason.
%
% comp.get_sys, bus.get_sys, con.get_sys and gc.get_sys also return a ResultLIN (an
% object-level result, output.s_layer "Component", "Bus", "LocalController" or
% "GlobalController"; "PowerNetwork" for net.linearize). It holds the port model of the
% layer in A ... OutputName, the point rv_point and the Jacobian blocks that apply
% (rm_Axx, rm_Axv, rm_Bx, rm_E; see the help of each get_sys); get_ss returns that model,
% and Method and Coordinate do not apply.
%
% - `tab_variable` has one row per variable with Index, Kind ("x" | "Vre" | "Vim" | "u"),
%   Owner, Name, Label and Bus (see PowerNetwork.get_variable_map).
% - `sct_model` holds the bus models (V2I, at the point), the global controller models, the
%   admittance matrix, the non-unit buses and the bus voltages at the point: used by
%   get_ss("Feedback") and the coordinates of get_ss("DAE"). The Output option of get_ss
%   also uses the names of the bus currents (sv_I) and the outputs of the bus models
%   (sct_output). The result holds computed values only; the network is not changed.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% [result, flag] = net.linearize();
% eig(full(result.rm_Axx))          % Jacobian blocks of the unreduced DAE
% eig(result.A, result.E)           % model of options.Method
% sct = result.get_ss("Kron", Format="struct");   % reduced model as a struct
% sys = result.get_ss("Kron");      % ss object (Control System Toolbox)
% result.Plot();                    % eigenvalue map
% ```
%
% See also SolverLIN, ResultBase

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
    properties (SetAccess=private) % Model
        A double = zeros(0,0)                  % State matrix of the model (E dx/dt = A x + B u, y = C x + D u): get_ss(options.Method), or the port model of an object-level result.
        B double = zeros(0,0)                  % Input matrix of the model.
        C double = zeros(0,0)                  % Output matrix of the model.
        D double = zeros(0,0)                  % Feedthrough matrix of the model.
        E double = zeros(0,0)                  % Mass matrix of the model (singular for "DAE").
        StateName (:,1) string = strings(0,1)  % Names of the states of the model.
        InputName (:,1) string = strings(0,1)  % Names of the inputs of the model.
        OutputName (:,1) string = strings(0,1) % Names of the outputs of the model ("Kron" has none by default).
    end
    properties (SetAccess=private, Hidden) % Model data
        sct_model struct = struct()            % Model data of get_ss: bus and global controller models, admittance matrix, ... (see the class help).
    end

    methods
        function obj = ResultLIN(net, solver, options, flag, output, elapsed, tab_variable, rv_point, sct_block, sct_model)
        % Create a linearization result.
        %
        % Stores the computed values of a linearization.
            arguments (Input)
                net                 = [] % Analysed network; see ResultBase.
                solver              = "SolverLIN" % Solver object or its class name; see ResultBase.
                options      struct = struct() % Effective settings; see ResultBase.
                flag                = false % Success or convergence flag; see ResultBase.
                output       struct = struct() % Solver details; see ResultBase.
                elapsed             = NaN % [s] Elapsed time or tic value; see ResultBase.
                tab_variable table  = table() % Variable map.
                rv_point     double = zeros(0,1) % Point in the order of tab_variable.
                sct_block    struct = struct() % Fields Axx, Axv, Bx, Avx, Avv, Bv, E.
                sct_model    struct = struct() % Data for get_ss (bus and controller models, Y, non-unit buses, V), or the port model (field sct_sys) of an object-level result.
            end
            arguments (Output)
                obj % The result object.
            end
            obj@ResultBase(net, solver, options, flag, output, elapsed);
            obj.tab_variable = tab_variable;
            obj.rv_point     = rv_point(:);
            for str = ["Axx","Axv","Bx","Avx","Avv","Bv","E"]
                if isfield(sct_block, str)
                    obj.("rm_" + str) = sct_block.(str);
                end
            end
            obj.sct_model = sct_model;

            % The model: the port model of an object-level result, or get_ss(Method)
            if isfield(sct_model, "sct_sys")
                sct_sys = sct_model.sct_sys;
            elseif isfield(options, "Method") && isfield(sct_model, "c_sysBus")
                c_nv = cell(1,0);       % Input and Output of net.get_sys
                for str = ["Input","Output"]
                    if isfield(options, str)
                        c_nv = [c_nv, {str, options.(str)}]; %#ok<AGROW>
                    end
                end
                try
                    sct_sys = obj.get_ss(options.Method, c_nv{:}, Format="struct");
                catch
                    sct_sys = [];   % flag false or no model for this Method: get_ss gives the reason
                end
            else
                sct_sys = [];
            end
            if ~isempty(sct_sys)
                for str = ["A","B","C","D","E","StateName","InputName","OutputName"]
                    obj.(str) = sct_sys.(str);
                end
            end
        end

        sys = get_ss(obj, Method, opt)
        fig = Plot(obj, opt)
    end
end

