classdef PowerFlowResult < AnalysisResult
% <@Desc>
% Result of net.calculate_powerflow: the bus voltages, currents and power injections of
% the solution, the branch flows, and the voltages at each iteration (or time step of the
% "dynamic" method). It holds computed values only; the power flow settings of the buses
% and components stay with the network.
% Plot draws the voltage profile. Export writes the bus or branch table (CSV, Excel) or
% the iteration history (JSON for the GridSpring viewer).
% <@Role> Class Category
% <@Constructor>
% result = PowerFlowResult(net, solver, options, flag, output, elapsed, tab_bus, tab_branch, cm_Vhistory, rv_step)
% Created by PowerFlowCalculation.solve.

    properties (SetAccess=private)
        % <@Desc> Bus values of the solution, one row per bus (row names = bus tags):
        % Varg [rad], V [pu], P, Q (injections into the network) [pu], Vphasor, Iphasor [pu].
        % The same table as the first output of calculate_powerflow in v3.
        % <@Role> Result
        % <@Type> table
        % <@Size> n_bus x 6
        tab_bus table = table()

        % <@Desc> Branch flows, one row per branch (row names = branch tags). "from" is
        % br.a_Bus{1}, "to" is br.a_Bus{2}. Pfrom, Qfrom, Pto, Qto: power flowing into the
        % branch at each end [pu]; Ifrom, Ito: current phasors into the branch [pu];
        % Ploss, Qloss: losses of the branch (sum of both ends) [pu].
        % <@Role> Result
        % <@Type> table
        % <@Size> n_branch x 8
        tab_branch table = table()

        % <@Desc> Bus voltage phasors at each iteration ("algebraic") or output time
        % ("dynamic"), one row per bus in the order of tab_bus.
        % <@Role> Result
        % <@Type> complex double
        % <@Size> n_bus x n_step
        cm_Vhistory double = zeros(0,0)

        % <@Desc> Iteration numbers ("algebraic") or times [s] ("dynamic") of cm_Vhistory.
        % <@Role> Result
        % <@Type> double
        % <@Size> 1 x n_step
        rv_step double = zeros(1,0)
    end

    methods
        function obj = PowerFlowResult(net, solver, options, flag, output, elapsed, tab_bus, tab_branch, cm_Vhistory, rv_step)
        % <@Desc>
        % Stores the computed values of a power flow calculation.
        % <@Role> Constructor
        % <@Summary> Create a power flow result.
        % <@Signatures>
        % [
        %   "result = PowerFlowResult()",
        %   "result = PowerFlowResult(net, solver, options, flag, output, elapsed, tab_bus, tab_branch, cm_Vhistory, rv_step)"
        % ]
        % <@Parameters>
        % [
        %   {"Name": "net, solver, options, flag, output, elapsed", "Type": "-", "Description": "Shared part, see AnalysisResult.", "Required": false, "Default": "-"},
        %   {"Name": "tab_bus", "Type": "table", "Description": "Bus values (see tab_bus).", "Required": false, "Default": "table()"},
        %   {"Name": "tab_branch", "Type": "table", "Description": "Branch flows (see tab_branch).", "Required": false, "Default": "table()"},
        %   {"Name": "cm_Vhistory", "Type": "complex double", "Description": "Bus voltages at each step.", "Required": false, "Default": "[]"},
        %   {"Name": "rv_step", "Type": "double", "Description": "Iteration numbers or times of cm_Vhistory.", "Required": false, "Default": "[]"}
        % ]
        % <@Returns>
        % [
        %   {"Name": "result", "Type": "PowerFlowResult", "Description": "The result object."}
        % ]
            arguments
                net               = []
                solver            = "PowerFlowCalculation"
                options    struct = struct()
                flag              = false
                output     struct = struct()
                elapsed           = NaN
                tab_bus    table  = table()
                tab_branch table  = table()
                cm_Vhistory double = zeros(0,0)
                rv_step    double = zeros(1,0)
            end
            obj@AnalysisResult(net, solver, options, flag, output, elapsed);
            obj.tab_bus     = tab_bus;
            obj.tab_branch  = tab_branch;
            obj.cm_Vhistory = cm_Vhistory;
            obj.rv_step     = reshape(rv_step, 1, []);
        end

        fig = Plot(obj, opt)
        str_file = Export(obj, filename, opt)
    end
end
