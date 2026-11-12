classdef ResultOPF < ResultBase
% Result of net.calculate_optimal_powerflow.
%
% Holds the optimal bus values, the injection of every connection into its bus (components
% and branch ends), the branch flows, the optimal cost, the Lagrange multipliers and the
% solved optimization problem. The columns of the tables depend on the method: "AC OPF"
% has voltages, P, Q and currents, "DC OPF" has Varg, V (= 1) and P, "ELD" has P only
% (branches are ignored and their values are NaN). It is built from data only: the
% solution of SolverOPF.solve, a snapshot of the network (struct(net, false), of which it
% keeps the tag) and the solver information. It keeps no reference to the network, so a
% later edit of the network does not change it; the OPF settings (tab_parameter.OPF /
% .operation) stay with the network. plot_dispatch draws the component outputs
% and, for "DC OPF" and "AC OPF", the bus voltages. export writes the bus, connection or
% branch table (CSV, Excel).
%
% - `tab_bus`: row names = bus tags. "AC OPF": Varg [rad], V [pu], P, Q (injections into
%   the network) [pu], Vphasor, Iphasor [pu]; "DC OPF": Varg, V, P; "ELD": P.
% - `tab_cub`: rows are the components of each bus (row name "<component>"), then the
%   branch ends at the bus ("<branch>_<bus>"). "AC OPF": Iphasor, P, Q [pu]; "DC OPF" and
%   "ELD": P (NaN for branch ends in "ELD").
% - `tab_branch`: row names = branch tags. "from" is br.a_Bus{1}, "to" is br.a_Bus{2};
%   values flow into the branch at each end, as in ResultPF.tab_branch. "AC OPF": Pfrom,
%   Qfrom, Pto, Qto, Ifrom, Ito, Ploss, Qloss; "DC OPF" and "ELD": Pfrom, Pto, Ploss (NaN
%   in "ELD").
% - `lambda` is the fifth output of solve of the Optimization Toolbox.
%   lambda.Constraints.balancedP_<bus> (balancedP in "ELD") is the change of the optimal
%   cost per unit of injection at the bus, so the nodal price of active power (cost per
%   unit of load) is -lambda.Constraints.balancedP_<bus>; balancedQ_<bus> ("AC OPF") is
%   the same for reactive power. Branch limits are in
%   lambda.Constraints.Imax_<branch>_<bus> and Smax_<branch>_<bus>; bound multipliers (e.g.
%   the branch Pmax) are in lambda.Variables.<name>.Lower/Upper.
% - `OPFprob` is the solved problem: built by SolverOPF.build_problem, or the Problem given to calculate_optimal_powerflow.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% [result, flag] = net.calculate_optimal_powerflow(Method="AC OPF");
% result.r_cost            % optimal generation cost
% result.tab_cub           % P, Q of each component and branch end
% price = -result.lambda.Constraints.balancedP_B001;   % nodal price at bus B001
% result.plot_dispatch();
% result.export("opf.csv", Table="cub");
% ```
%
% See also SolverOPF, ResultBase

    properties (SetAccess=private) % Result
        tab_bus table = table()     % Bus values of the solution, one row per bus; columns by method (see the class help).
        tab_cub table = table()     % Injection into the bus of each connection (components, then branch ends), in bus order (see the class help).
        tab_branch table = table()  % Branch flows into the branch at each end, one row per branch; columns by method (see the class help).
        r_cost (1,1) double = NaN   % Optimal value of the objective (total generation cost of tab_parameter.OPF).
        lambda struct = struct()    % Lagrange multipliers of the solution, by constraint and variable name (see the class help).
        OPFprob = []                % Optimization problem that was solved; its Description shows the OPF settings of the run. <@Type> optim.problemdef.OptimizationProblem (1x1 or empty)
    end

    methods
        function obj = ResultOPF(sct_network, sct_solution, sct_solver)
        % Create an optimal power flow result from data.
        %
        % Stores the solution of an optimal power flow; no network object is read. The
        % network is known by the tag of its snapshot only (s_network).
            arguments (Input)
                sct_network  struct = struct() % Snapshot of the network: struct(net, false).
                sct_solution struct = struct() % Solution (output of SolverOPF.solve): tab_bus, tab_cub, tab_branch, r_cost, lambda, OPFprob; absent fields keep their defaults.
                sct_solver   struct = struct() % Solver information: solver, options, flag, output, elapsed (s or a tic value); absent fields keep the defaults of ResultBase.
            end
            arguments (Output)
                obj % The result object.
            end
            sct_info = struct("solver", "SolverOPF", "options", struct(), "flag", false, "output", struct(), "elapsed", NaN);
            for s_name = intersect(string(fieldnames(sct_solver)).', string(fieldnames(sct_info)).')
                sct_info.(s_name) = sct_solver.(s_name);
            end
            obj@ResultBase([], sct_info.solver, sct_info.options, sct_info.flag, sct_info.output, sct_info.elapsed);
            if isfield(sct_network, "s_tag")
                obj.s_network = string(sct_network.s_tag);
            end
            for s_name = intersect(string(fieldnames(sct_solution)).', ["tab_bus","tab_cub","tab_branch","r_cost","lambda","OPFprob"])
                obj.(s_name) = sct_solution.(s_name);
            end
        end

        fig = plot_dispatch(obj, opt)
        s_file = export(obj, filename, opt)
    end

    methods (Access=protected)
        l = is_success(obj)
    end
end
