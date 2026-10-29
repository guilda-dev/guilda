classdef OPFResult < AnalysisResult
% <@Desc>
% Result of net.optimize_powerflow: the optimal bus values, the injection of every
% connection into its bus (components and branch ends), the branch flows, the optimal
% cost, the Lagrange multipliers and the solved optimization problem. The columns of the
% tables depend on the method: "AC OPF" has voltages, P, Q and currents, "DC OPF" has
% Varg, V (= 1) and P, "ELD" has P only (branches are ignored and their values are NaN).
% It holds computed values only; the OPF settings (tab_parameter.OPF / .operation) stay
% with the network.
% Plot draws the component outputs and, for "DC OPF" and "AC OPF", the bus voltages.
% Export writes the bus, connection or branch table (CSV, Excel).
% <@Role> Class Category
% <@Constructor>
% result = OPFResult(net, solver, options, flag, output, elapsed, tab_bus, tab_cub, tab_branch, r_cost, lambda, OPFprob)
% Created by OptimalPowerFlow.solve.

    properties (SetAccess=private)
        % <@Desc> Bus values of the solution, one row per bus (row names = bus tags).
        % "AC OPF": Varg [rad], V [pu], P, Q (injections into the network) [pu], Vphasor,
        % Iphasor [pu]; "DC OPF": Varg, V, P; "ELD": P.
        % The same table as the first output of optimize_powerflow in v3.
        % <@Role> Result
        % <@Type> table
        % <@Size> n_bus x (6 | 3 | 1)
        tab_bus table = table()

        % <@Desc> Injection into the bus of each connection, in bus order: the components
        % of the bus (row name "<component>"), then the branch ends at the bus
        % ("<branch>_<bus>"). "AC OPF": Iphasor, P, Q [pu]; "DC OPF" and "ELD": P (NaN for
        % branch ends in "ELD").
        % The same table as the second output of optimize_powerflow in v3.
        % <@Role> Result
        % <@Type> table
        % <@Size> n_connection x (3 | 1)
        tab_cub table = table()

        % <@Desc> Branch flows, one row per branch (row names = branch tags). "from" is
        % br.a_Bus{1}, "to" is br.a_Bus{2}; values flow into the branch at each end, as in
        % PowerFlowResult.tab_branch. "AC OPF": Pfrom, Qfrom, Pto, Qto, Ifrom, Ito, Ploss,
        % Qloss; "DC OPF" and "ELD": Pfrom, Pto, Ploss (NaN in "ELD").
        % <@Role> Result
        % <@Type> table
        % <@Size> n_branch x (8 | 3)
        tab_branch table = table()

        % <@Desc> Optimal value of the objective (total generation cost of tab_parameter.OPF).
        % <@Role> Result
        % <@Type> double
        % <@Size> 1x1
        r_cost (1,1) double = NaN

        % <@Desc> Lagrange multipliers of the solution (fifth output of solve of the
        % Optimization Toolbox), labeled by constraint and variable name.
        % lambda.Constraints.balancedP_<bus> (balancedP in "ELD") is the change of the
        % optimal cost per unit of injection at the bus, so the nodal price of active
        % power (cost per unit of load) is -lambda.Constraints.balancedP_<bus>;
        % balancedQ_<bus> ("AC OPF") is the same for reactive power. Branch limits are in
        % lambda.Constraints.Imax_<branch>_<bus> and Smax_<branch>_<bus>; bound
        % multipliers (e.g. the branch Pmax) are in lambda.Variables.<name>.Lower/Upper.
        % <@Role> Result
        % <@Type> struct
        % <@Size> 1x1
        lambda struct = struct()

        % <@Desc> The optimization problem that was solved (built by build_opf_problem).
        % Its Description shows the OPF settings of the network at the time of the run.
        % <@Role> Result
        % <@Type> optim.problemdef.OptimizationProblem
        % <@Size> 1x1 or empty
        OPFprob = []
    end

    methods
        function obj = OPFResult(net, solver, options, flag, output, elapsed, tab_bus, tab_cub, tab_branch, r_cost, lambda, OPFprob)
        % <@Desc>
        % Stores the computed values of an optimal power flow.
        % <@Role> Constructor
        % <@Summary> Create an optimal power flow result.
        % <@Signatures>
        % [
        %   "result = OPFResult()",
        %   "result = OPFResult(net, solver, options, flag, output, elapsed, tab_bus, tab_cub, tab_branch, r_cost, lambda, OPFprob)"
        % ]
        % <@Parameters>
        % [
        %   {"Name": "net, solver, options, flag, output, elapsed", "Type": "-", "Description": "Shared part, see AnalysisResult.", "Required": false, "Default": "-"},
        %   {"Name": "tab_bus", "Type": "table", "Description": "Bus values (see tab_bus).", "Required": false, "Default": "table()"},
        %   {"Name": "tab_cub", "Type": "table", "Description": "Injections of the connections (see tab_cub).", "Required": false, "Default": "table()"},
        %   {"Name": "tab_branch", "Type": "table", "Description": "Branch flows (see tab_branch).", "Required": false, "Default": "table()"},
        %   {"Name": "r_cost", "Type": "double", "Description": "Optimal objective value.", "Required": false, "Default": "NaN"},
        %   {"Name": "lambda", "Type": "struct", "Description": "Lagrange multipliers.", "Required": false, "Default": "struct()"},
        %   {"Name": "OPFprob", "Type": "OptimizationProblem", "Description": "Solved problem.", "Required": false, "Default": "[]"}
        % ]
        % <@Returns>
        % [
        %   {"Name": "result", "Type": "OPFResult", "Description": "The result object."}
        % ]
            arguments
                net               = []
                solver            = "OptimalPowerFlow"
                options    struct = struct()
                flag              = false
                output     struct = struct()
                elapsed           = NaN
                tab_bus    table  = table()
                tab_cub    table  = table()
                tab_branch table  = table()
                r_cost     double = NaN
                lambda     struct = struct()
                OPFprob           = []
            end
            obj@AnalysisResult(net, solver, options, flag, output, elapsed);
            obj.tab_bus    = tab_bus;
            obj.tab_cub    = tab_cub;
            obj.tab_branch = tab_branch;
            obj.r_cost     = r_cost;
            obj.lambda     = lambda;
            obj.OPFprob    = OPFprob;
        end

        fig = Plot(obj, opt)
        str_file = Export(obj, filename, opt)
    end

    methods (Access=protected)
        function l = is_success(obj)
        % <@Desc>
        % Success test behind l_success: the exitflag of solve (an
        % optim.problemdef.ExitFlag or a number) is positive.
        % <@Role> Result
        % <@Summary> Decide whether flag means success.
        % <@Signatures>
        % [
        %   "l = is_success(obj)"
        % ]
        % <@Returns>
        % [
        %   {"Name": "l", "Type": "logical scalar", "Description": "True when the problem was solved."}
        % ]
            f = obj.flag;
            if islogical(f)
                l = isscalar(f) && f;
            else
                l = isscalar(f) && double(f) > 0;
            end
        end
    end
end
