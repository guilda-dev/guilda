classdef LinearizationResult < AnalysisResult
% <@Desc>
% Result of net.linearize: the unreduced linear DAE of the network at one point,
%   rm_E dx/dt = rm_Axx x + rm_Axv v + rm_Bx u
%            0 = rm_Avx x + rm_Avv v + rm_Bv u
% where x are the states, v = [Vre1; Vim1; Vre2; ...] the bus voltages and u the inputs,
% all in the order of the variable map tab_variable (= net.get_variable_map() at the time
% of the analysis). The algebraic equations are the current balance of each bus,
% 0 = (Y v - I of the components), in the order of v. The values are deviations from the
% point rv_point.
% get_ss returns a reduced state-space model (Kron / Feedback / DAE); Plot draws the
% eigenvalue map. The result holds computed values only; the network is not changed.
% <@Role> Class Category
% <@Constructor>
% result = LinearizationResult(net, solver, options, flag, output, elapsed, tab_variable, rv_point, s_block, s_model)
% Created by odeLinearizer.solve.

    properties (SetAccess=private)
        % <@Desc> Variable map at the time of the analysis (see PowerNetwork.get_variable_map):
        % one row per variable with Index, Kind ("x" | "Vre" | "Vim" | "u"), Owner, Name,
        % Label, Bus. It is the order of the rows and columns of the Jacobian blocks.
        % <@Role> Result
        % <@Type> table
        % <@Size> (n_x + n_v + n_u) x 6
        tab_variable table = table()

        % <@Desc> Point of the linearization: the values of the variables in the order of
        % tab_variable (the equilibrium when output.l_equilibrium is true).
        % <@Role> Result
        % <@Type> double
        % <@Size> (n_x + n_v + n_u) x 1
        rv_point (:,1) double = zeros(0,1)

        % <@Desc> d(dx/dt)/dx: Jacobian of the state equations with respect to the states.
        % <@Role> Result
        % <@Type> double
        % <@Size> n_x x n_x
        rm_Axx double = zeros(0,0)

        % <@Desc> d(dx/dt)/dv: Jacobian of the state equations with respect to the bus voltages.
        % <@Role> Result
        % <@Type> double
        % <@Size> n_x x n_v
        rm_Axv double = zeros(0,0)

        % <@Desc> d(dx/dt)/du: Jacobian of the state equations with respect to the inputs.
        % <@Role> Result
        % <@Type> double
        % <@Size> n_x x n_u
        rm_Bx double = zeros(0,0)

        % <@Desc> Jacobian of the bus current balance (Y v - I) with respect to the states.
        % <@Role> Result
        % <@Type> double
        % <@Size> n_v x n_x
        rm_Avx double = zeros(0,0)

        % <@Desc> Jacobian of the bus current balance (Y v - I) with respect to the bus
        % voltages (the admittance matrix minus the component terms).
        % <@Role> Result
        % <@Type> double
        % <@Size> n_v x n_v
        rm_Avv double = zeros(0,0)

        % <@Desc> Jacobian of the bus current balance (Y v - I) with respect to the inputs.
        % <@Role> Result
        % <@Type> double
        % <@Size> n_v x n_u
        rm_Bv double = zeros(0,0)

        % <@Desc> Mass matrix of the state equations (the algebraic equations have none).
        % <@Role> Result
        % <@Type> double
        % <@Size> n_x x n_x
        rm_E double = zeros(0,0)
    end
    properties (SetAccess=private, Hidden)
        % Bus models (V2I, at the point), global controller models, admittance matrix,
        % non-unit buses and bus voltages at the point: used by get_ss("Feedback") and
        % the coordinates of get_ss("DAE")
        s_model struct = struct()
    end

    methods
        function obj = LinearizationResult(net, solver, options, flag, output, elapsed, tab_variable, rv_point, s_block, s_model)
        % <@Desc>
        % Stores the computed values of a linearization.
        % <@Role> Constructor
        % <@Summary> Create a linearization result.
        % <@Signatures>
        % [
        %   "result = LinearizationResult()",
        %   "result = LinearizationResult(net, solver, options, flag, output, elapsed, tab_variable, rv_point, s_block, s_model)"
        % ]
        % <@Parameters>
        % [
        %   {"Name": "net, solver, options, flag, output, elapsed", "Type": "-", "Description": "Shared part, see AnalysisResult.", "Required": false, "Default": "-"},
        %   {"Name": "tab_variable", "Type": "table", "Description": "Variable map.", "Required": false, "Default": "table()"},
        %   {"Name": "rv_point", "Type": "double", "Description": "Point in the order of tab_variable.", "Required": false, "Default": "[]"},
        %   {"Name": "s_block", "Type": "struct", "Description": "Fields Axx, Axv, Bx, Avx, Avv, Bv, E.", "Required": false, "Default": "struct()"},
        %   {"Name": "s_model", "Type": "struct", "Description": "Data for get_ss (bus and controller models, Y, non-unit buses, V).", "Required": false, "Default": "struct()"}
        % ]
        % <@Returns>
        % [
        %   {"Name": "result", "Type": "LinearizationResult", "Description": "The result object."}
        % ]
            arguments
                net                 = []
                solver              = "odeLinearizer"
                options      struct = struct()
                flag                = false
                output       struct = struct()
                elapsed             = NaN
                tab_variable table  = table()
                rv_point     double = zeros(0,1)
                s_block      struct = struct()
                s_model      struct = struct()
            end
            obj@AnalysisResult(net, solver, options, flag, output, elapsed);
            obj.tab_variable = tab_variable;
            obj.rv_point     = rv_point(:);
            for str = ["Axx","Axv","Bx","Avx","Avv","Bv","E"]
                if isfield(s_block, str)
                    obj.("rm_" + str) = s_block.(str);
                end
            end
            obj.s_model = s_model;
        end

        sys = get_ss(obj, Algorithm, opt)
        fig = Plot(obj, opt)
    end
end
