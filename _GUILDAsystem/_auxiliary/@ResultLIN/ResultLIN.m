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
% point rv_point. Away from an equilibrium the tangent of the nonlinear system also has the
% constant rv_residual: its rows add to the right-hand sides above, and get_ss leaves it out.
% Y is the admittance matrix of the model, also at a point inside a fault.
% get_ss returns a reduced state-space model (Kron / Feedback / DAE); Plot draws the
% eigenvalue map.
%
% - `tab_variable` has one row per variable with Index, Kind ("x" | "Vre" | "Vim" | "u"),
%   Owner, Name, Label and Bus (see PowerNetwork.get_variable_map).
% - `rv_residual` holds the right-hand sides of the state equations, then Y v - I of each
%   bus, with the inputs at their values in rv_point.
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
% sys = result.get_ss("Kron");      % reduced state-space model
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
        rv_residual (:,1) double = zeros(0,1)  % Residual of the nonlinear DAE at rv_point, rows x and v of tab_variable; zero at an equilibrium.
    end
    properties (SetAccess=private, Hidden) % Model data
        sct_model struct = struct()            % Model data of get_ss: bus and global controller models, admittance matrix, ... (see the class help).
    end

    methods
        function obj = ResultLIN(net, solver, options, flag, output, elapsed, tab_variable, rv_point, sct_block, sct_model, rv_residual)
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
                sct_model    struct = struct() % Data for get_ss (bus and controller models, Y, non-unit buses, V).
                rv_residual  double = zeros(0,1) % Residual at the point (rows x and v of tab_variable).
            end
            arguments (Output)
                obj % The result object.
            end
            obj@ResultBase(net, solver, options, flag, output, elapsed);
            obj.tab_variable = tab_variable;
            obj.rv_point     = rv_point(:);
            obj.rv_residual  = rv_residual(:);
            for str = ["Axx","Axv","Bx","Avx","Avv","Bv","E"]
                if isfield(sct_block, str)
                    obj.("rm_" + str) = sct_block.(str);
                end
            end
            obj.sct_model = sct_model;
        end

        sys = get_ss(obj, Algorithm, opt)
        fig = Plot(obj, opt)
    end
end
