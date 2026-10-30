classdef OPFResult < AnalysisResult
% Result of net.optimize_powerflow.
%
% Holds the optimal bus values, the injection of every connection into its bus (components
% and branch ends), the branch flows, the optimal cost, the Lagrange multipliers and the
% solved optimization problem. The columns of the tables depend on the method: "AC OPF" has voltages, P, Q and
% currents, "DC OPF" has Varg, V (= 1) and P, "ELD" has P only (branches are ignored and
% their values are NaN). It holds computed values only; the OPF settings
% (tab_parameter.OPF / .operation) stay with the network. Plot draws the component outputs
% and, for "DC OPF" and "AC OPF", the bus voltages. Export writes the bus, connection or
% branch table (CSV, Excel).
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% [result, flag] = net.optimize_powerflow(Method="AC OPF");
% result.r_cost            % optimal generation cost
% result.tab_cub           % P, Q of each component and branch end
% price = -result.lambda.Constraints.balancedP_B001;   % nodal price at bus B001
% result.Plot();
% result.Export("opf.csv", Table="cub");
% ```
%
% See also OptimalPowerFlow, AnalysisResult

    properties (SetAccess=private) % Result
        % Bus values of the solution, one row per bus (row names = bus tags).
        % "AC OPF": Varg [rad], V [pu], P, Q (injections into the network) [pu], Vphasor, Iphasor
        % [pu]; "DC OPF": Varg, V, P; "ELD": P. The same table as the first output of
        % optimize_powerflow in v3.
        tab_bus table = table()

        % Injection into the bus of each connection, in bus order.
        % Rows: the components of the bus (row name "<component>"), then the branch ends at the
        % bus ("<branch>_<bus>"). "AC OPF": Iphasor, P, Q [pu]; "DC OPF" and "ELD": P (NaN for branch ends in "ELD"). The
        % same table as the second output of optimize_powerflow in v3.
        tab_cub table = table()

        % Branch flows, one row per branch (row names = branch tags).
        % "from" is br.a_Bus{1}, "to" is br.a_Bus{2}; values flow into the branch at each end, as
        % in PowerFlowResult.tab_branch. "AC OPF": Pfrom, Qfrom, Pto, Qto, Ifrom, Ito, Ploss,
        % Qloss; "DC OPF" and "ELD": Pfrom, Pto, Ploss (NaN in "ELD").
        tab_branch table = table()

        % Optimal value of the objective (total generation cost of tab_parameter.OPF).
        r_cost (1,1) double = NaN

        % Lagrange multipliers of the solution, labeled by constraint and variable name.
        % The fifth output of solve of the Optimization Toolbox.
        % lambda.Constraints.balancedP_<bus> (balancedP in "ELD") is the change of the optimal
        % cost per unit of injection at the bus, so the nodal price of active power (cost per
        % unit of load) is -lambda.Constraints.balancedP_<bus>; balancedQ_<bus> ("AC OPF") is
        % the same for reactive power. Branch limits are in lambda.Constraints.Imax_<branch>_<bus> and Smax_<branch>_<bus>;
        % bound multipliers (e.g. the branch Pmax) are in lambda.Variables.<name>.Lower/Upper.
        lambda struct = struct()

        % The optimization problem that was solved (built by build_opf_problem).
        % Its Description shows the OPF settings of the network at the time of the run.
        % <@Type> optim.problemdef.OptimizationProblem (1x1 or empty)
        OPFprob = []
    end

    methods
        function obj = OPFResult(net, solver, options, flag, output, elapsed, tab_bus, tab_cub, tab_branch, r_cost, lambda, OPFprob)
        % Create an optimal power flow result.
        %
        % Stores the computed values of an optimal power flow.
            arguments
                net               = [] % Analysed network; see AnalysisResult.
                solver            = "OptimalPowerFlow" % Solver object or its class name; see AnalysisResult.
                options    struct = struct() % Effective settings; see AnalysisResult.
                flag              = false % Success or convergence flag; see AnalysisResult.
                output     struct = struct() % Solver details; see AnalysisResult.
                elapsed           = NaN % [s] Elapsed time or tic value; see AnalysisResult.
                tab_bus    table  = table() % Bus values (see tab_bus).
                tab_cub    table  = table() % Injections of the connections (see tab_cub).
                tab_branch table  = table() % Branch flows (see tab_branch).
                r_cost     double = NaN % Optimal objective value.
                lambda     struct = struct() % Lagrange multipliers.
                OPFprob           = [] % Solved problem.
            end
            arguments (Output)
                obj % The result object.
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
        % Decide whether flag means success.
        %
        % Success test behind l_success: the exitflag of solve (an
        % optim.problemdef.ExitFlag or a number) is positive.
            arguments (Output)
                l % True when the problem was solved.
            end
            f = obj.flag;
            if islogical(f)
                l = isscalar(f) && f;
            else
                l = isscalar(f) && double(f) > 0;
            end
        end
    end
end
