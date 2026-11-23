classdef ResultOPF < ResultBase
% Result of net.calculate_optimal_powerflow.
%
% Holds the optimal bus values, the injection of every connection into its bus (components
% and branch ends), the branch flows, the optimal cost, the Lagrange multipliers and the
% solved optimization problem. The columns of the tables depend on the method: "AC OPF"
% has voltages, P, Q and currents, "DC OPF" has Varg, V (= 1) and P, "ELD" has P only
% (branches are ignored and their values are NaN). It is built from data only: the
% solution of SolverOPF.solve, a snapshot of the network (struct(net, false), kept as
% sct_network) and the solver information. It keeps no reference to the network, so a
% later edit of the network does not change it; the OPF settings (tab_parameter.OPF /
% .operation) stay with the network. plot_dispatch draws the component outputs
% and, for "DC OPF" and "AC OPF", the bus voltages. export writes the bus, connection or
% branch table (CSV, Excel). disp_summary (get_summary as a struct), disp_binding and get_lmp show what the solution
% is made of (the binding constraints and the nodal prices with their components);
% plot_lmp draws the prices on the network diagram, and plot_iteration the iterations of
% an "AC OPF" (sct_iteration) as a chart.
%
% - `tab_bus`: row names = bus tags. "AC OPF": Varg [rad], V [pu], P, Q (injections into
%   the network) [pu], Vphasor, Iphasor [pu]; "DC OPF": Varg, V, P; "ELD": P.
% - `tab_cub`: rows are the components of each bus (row name "<component>"), then the
%   branch ends at the bus ("<branch>_<bus>"). "AC OPF": Iphasor, P, Q [pu]; "DC OPF" and
%   "ELD": P (NaN for branch ends in "ELD").
% - The branch-end rows of `tab_cub` and `tab_branch` are computed from the solved bus
%   voltages (the problem has no branch variables).
% - `tab_branch`: row names = branch tags. "from" is br.a_Bus{1}, "to" is br.a_Bus{2};
%   values flow into the branch at each end, as in ResultPF.tab_branch. "AC OPF": Pfrom,
%   Qfrom, Pto, Qto, Ifrom, Ito, Ploss, Qloss; "DC OPF" and "ELD": Pfrom, Pto, Ploss (NaN
%   in "ELD").
% - `lambda` is the fifth output of solve of the Optimization Toolbox.
%   lambda.Constraints.balancedP_<bus> (balancedP in "ELD") is the change of the optimal
%   cost per unit of injection at the bus, so the nodal price of active power (cost per
%   unit of load) is -lambda.Constraints.balancedP_<bus>; balancedQ_<bus> ("AC OPF") is
%   the same for reactive power. Branch limits are in lambda.Constraints.Pmax_<branch>_<bus>
%   and Qmax_<branch>_<bus> (two values: P <= Pmax, -P <= Pmax), Imax_<branch>_<bus>,
%   Smax_<branch>_<bus>, VargMax1_<branch> and VargMax2_<branch>; the bound multipliers of
%   the buses and components are in lambda.Variables.<tag>.Lower/Upper.
% - `OPFprob` is the solved problem: built by SolverOPF.build_problem, or the Problem given to calculate_optimal_powerflow.
% - `sct_iteration` holds the iterations of fmincon ("AC OPF"), recorded at every run
%   through the OutputFcn of fmincon (next to PlotFcn): Iteration (1 x n, the iteration
%   numbers), Fval (objective), ConstrViolation (largest constraint violation) and X (a
%   struct by variable name of the problem, each variable's values as columns, one per
%   iteration). It is an empty struct for linprog and quadprog ("ELD", "DC OPF"), which
%   have no OutputFcn.
% - `sct_stability` holds the outer iterations of a stability-constrained "AC OPF"
%   (MinDampingRatio or MaxRealPart of calculate_optimal_powerflow): `tab_iteration`, one
%   row per outer iteration (Iteration, Cost, MinDampingRatio and MaxRealPart of the
%   eigenvalues of get_sys at its solution, CriticalMode: the modes that got linearized
%   constraints, those near the MinDampingRatio limit from the smallest damping ratio, then
%   those near the MaxRealPart limit only from the largest real part, Step: the trust region
%   [dP dV] [pu] of the next iteration, Flag: the exit flag of its OPF; an OPF that stopped
%   without a solution after the first iteration gives a last row with Cost, MinDampingRatio
%   and MaxRealPart NaN, and the result is then the solution of the row before it), and
%   `tab_mode`, the modes of the last solution (Eigenvalue,
%   Frequency [Hz], DampingRatio (NaN for a real mode), Owner: the tag of the component or
%   controller with the largest participation). It is an empty struct otherwise.
% - `sct_network` is the snapshot of the network at the calculation (struct(net, false)),
%   as in ResultPF; get_lmp reads its branch admittances and bus shunts, plot_lmp draws it.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% [result, flag] = net.calculate_optimal_powerflow(Method="AC OPF");
% result.r_cost            % optimal generation cost
% result.tab_cub           % P, Q of each component and branch end
% price = -result.lambda.Constraints.balancedP_B001;   % nodal price at bus B001
% G = result.plot_dispatch();     % bar charts of the solution (GraphChart)
% result.export("opf.csv", Table="cub");
% result.disp_summary();   % cost, generation, losses, binding constraints, price range
% sct = result.get_summary();  % the same values as a struct
% result.get_lmp()         % nodal prices and their energy, congestion and loss components
% result.plot_lmp();       % nodal prices on the network diagram
% G = result.plot_iteration();   % iterations of the AC OPF (GraphChart)
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
        sct_iteration struct = struct() % Iterations of fmincon: Iteration, Fval, ConstrViolation, X (see the class help); empty struct for linprog and quadprog.
        sct_stability struct = struct() % Stability-constrained OPF: tab_iteration and tab_mode (see the class help); empty struct without MinDampingRatio and MaxRealPart.
    end
    properties (SetAccess=private) % Data of the calculation
        sct_network struct = struct()   % Snapshot of the network at the calculation: struct(net, false), a nested struct without handles.
    end

    methods
        function obj = ResultOPF(sct_network, sct_solution, sct_solver)
        % Create an optimal power flow result from data.
        %
        % Stores the solution of an optimal power flow; no network object is read. The
        % network is known by the tag of its snapshot only (s_network).
            arguments (Input)
                sct_network  struct = struct()  % Snapshot of the network: struct(net, false).
                sct_solution struct = struct()  % Solution (output of SolverOPF.solve): tab_bus, tab_cub, tab_branch, r_cost, lambda, OPFprob, sct_iteration; absent fields keep their defaults.
                sct_solver   struct = struct()  % Solver information: solver, options, flag, output, elapsed (s or a tic value); absent fields keep the defaults of ResultBase.
            end
            arguments (Output)
                obj  % The result object.
            end
            sct_info = struct("solver", "SolverOPF", "options", struct(), "flag", false, "output", struct(), "elapsed", NaN);
            for s_name = intersect(string(fieldnames(sct_solver)).', string(fieldnames(sct_info)).')
                sct_info.(s_name) = sct_solver.(s_name);
            end
            obj@ResultBase([], sct_info.solver, sct_info.options, sct_info.flag, sct_info.output, sct_info.elapsed);
            if isfield(sct_network, "s_tag")
                obj.s_network = string(sct_network.s_tag);
            end
            obj.sct_network = sct_network;
            for s_name = intersect(string(fieldnames(sct_solution)).', ["tab_bus","tab_cub","tab_branch","r_cost","lambda","OPFprob","sct_iteration","sct_stability"])
                obj.(s_name) = sct_solution.(s_name);
            end
        end

        G = plot_dispatch(obj, opt)
        s_file = export(obj, filename, opt)
        varargout = disp_summary(obj)
        sct = get_summary(obj)
        varargout = disp_binding(obj, opt)
        tab = get_lmp(obj)
        G = plot_lmp(obj, opt)
        G = plot_iteration(obj, opt)
    end

    methods (Access=protected)
        l = is_success(obj)
    end
end
