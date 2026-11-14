function [sct_solution, flag, output] = solve(obj, prob, x0, tab_bus, tab_component, tab_branch, sct_options)
% Solve an optimal power flow problem and return the solution.
%
% Solves the problem prob (built by net.build_opf_problem, or given by the user) from the initial point x0 with the solver options of
% sct_options, and returns the solution as a struct; the problem is not built again and no
% network object is read. The tables of the buses, components and branches (the data the
% problem was built from) give the rows of the result tables; the caller builds the
% ResultOPF. A problem without these variables (or with other sizes) stops with
% GUILDA:SolverOPF:ProblemMismatch. With sct_options.WarmStart, the bus and branch-end values of x0 are replaced
% by the start from the bus voltages of the last solved "AC OPF" when it was solved for the
% same bus tags (in the same order); the solver keeps only these voltages, with their bus
% tags (see SolverOPF). Called by net.calculate_optimal_powerflow; calling it directly is
% for advanced use. Without Optimization Toolbox it stops with
% GUILDA:require_toolbox:Unavailable before anything is solved.
    arguments (Input)
        obj % Solver (net.solver_OPF).
        prob % optimproblem to solve; it holds the variables of the problem built from the tables.
        x0  (1,1) struct % Initial point: values by variable name.
        tab_bus       table % Buses (see build_problem).
        tab_component table % Components (see build_problem).
        tab_branch    table % Branches (see build_problem).
        sct_options (1,1) struct % Options of calculate_optimal_powerflow: Method, Solver, Tolerance, MaxIteration, Verbose, PlotFcn, WarmStart (see optimoption).
    end
    arguments (Output)
        sct_solution % tab_bus, tab_cub, tab_branch, r_cost, lambda and OPFprob (see ResultOPF).
        flag % exitflag of solve (positive = solved).
        output % Solver details; output.message describes the outcome.
    end
    tools.require_toolbox("optim", "OPF");
    if ~isa(prob, "optim.problemdef.OptimizationProblem")
        error(msg("GUILDA:SolverOPF:InvalidProblem"))
    end
    s_method = sct_options.Method;
    sv_bus   = string(tab_bus.Properties.RowNames);
    sv_com   = string(tab_component.Properties.RowNames);
    sv_br    = string(tab_branch.Properties.RowNames);

    % The problem must hold the variables that the result tables are read from, with their
    % sizes: buses [Varg; V], components [P; Q], branch ends [P; Q; Ireal; Iimag] in
    % "AC OPF", one value each in "DC OPF", the components only in "ELD"
    rv_n   = struct("AC_OPF", [2 2 4], "DC_OPF", [1 1 1], "ELD", [0 1 0]).(replace(s_method, " ", "_"));
    c_name = {sv_bus, sv_com, [sv_br + "_" + tab_branch.From; sv_br + "_" + tab_branch.To]};
    sv_bad = strings(0,1);
    for k = find(rv_n)
        lv_bad = arrayfun(@(s) ~isfield(prob.Variables, s) ...
            || ~isequal(size(prob.Variables.(s)), [rv_n(k) 1]), c_name{k});
        sv_bad = [sv_bad; c_name{k}(lv_bad)]; %#ok<AGROW>
    end
    if ~isempty(sv_bad)
        error(msg("GUILDA:SolverOPF:ProblemMismatch", s_method, join(sort(sv_bad), ", ")))
    end

    if sct_options.WarmStart && ~isempty(obj.sv_warmBus) && isequal(obj.sv_warmBus, sv_bus)
        x0 = start_point(x0, sv_bus, obj.rm_Vwarm, tab_branch, s_method);
    end

    % solve OPF problem
    [~, c_nv] = obj.optimoption(prob, sct_options);
    [sol,fval,flag,output,lambda] = solve(prob,x0,c_nv{:});
    if isstruct(fval)
        fval = sum(cell2mat(struct2cell(fval)));
    end

    % Buses and connections. tab_cub has one row per connection to a bus, in bus order: the
    % components of the bus ("<component>"), then the branch ends at the bus
    % ("<branch>_<bus>"); each row is the injection into the bus (Iphasor, P, Q).
    rm_bus = [];
    rm_cub = [];
    sv_cub = [];
    for i_bus = 1:numel(sv_bus)
        s_bus  = sv_bus(i_bus);
        sv_c   = sv_com(tab_component.Bus == s_bus);
        sv_bra = string.empty(0,1);
        for i_bra = 1:numel(sv_br)
            if tab_branch.From(i_bra) == s_bus || tab_branch.To(i_bra) == s_bus
                sv_bra = [sv_bra; sv_br(i_bra)+"_"+s_bus];  %#ok<AGROW>
            end
        end
        sv_cub = [sv_cub; sv_c(:); sv_bra];                 %#ok<AGROW>

        switch s_method
            case "AC OPF"
                sol_V = sol.(s_bus);
                c_V   = sol_V(2) * exp(1j*sol_V(1));
                r_P   = 0;
                r_Q   = 0;
                c_I   = 0;
                for i_com = 1:numel(sv_c)
                    sol_com = sol.(sv_c(i_com));
                    Pcub = sol_com(1);
                    Qcub = sol_com(2);
                    Icub = (Pcub-1j*Qcub)/conj(c_V);
                    r_P  = r_P + Pcub;
                    r_Q  = r_Q + Qcub;
                    c_I  = c_I + Icub;
                    rm_cub = [rm_cub; [Icub,Pcub,Qcub]];                    %#ok<AGROW>
                end
                for i_bra = 1:numel(sv_bra)
                    sol_bra = sol.(sv_bra(i_bra));
                    rm_cub  = [rm_cub; [sol_bra(3)+1j*sol_bra(4),sol_bra(1),sol_bra(2)]]; %#ok<AGROW>
                end
                rm_bus = [rm_bus; [sol_V(1),sol_V(2),r_P,r_Q,c_V,c_I]];    %#ok<AGROW>

            case "DC OPF"
                rv_P   = arrayfun(@(c) sol.(c), sv_c);
                rv_Pbr = arrayfun(@(s) sol.(s), sv_bra);
                rm_cub = [rm_cub; rv_P(:); rv_Pbr(:)];                      %#ok<AGROW>
                rm_bus = [rm_bus; [sol.(s_bus), 1, sum(rv_P)]];             %#ok<AGROW>

            case "ELD"
                % branches are ignored in ELD, so the branch rows are NaN
                rv_P   = arrayfun(@(c) sol.(c), sv_c);
                rm_cub = [rm_cub; rv_P(:); nan(numel(sv_bra),1)];          %#ok<AGROW>
                rm_bus = [rm_bus; sum(rv_P)];                               %#ok<AGROW>
        end
    end
    switch s_method
        case "AC OPF"
            tab_busSol = array2table(rm_bus, "VariableNames",["Varg","V","P","Q","Vphasor","Iphasor"], "RowNames",sv_bus);
            tab_cub    = array2table(rm_cub, "VariableNames",["Iphasor","P","Q"], "RowNames",sv_cub);
        case "DC OPF"
            tab_busSol = array2table(rm_bus, "VariableNames",["Varg","V","P"], "RowNames",sv_bus);
            tab_cub    = array2table(rm_cub, "VariableNames","P", "RowNames",sv_cub);
        case "ELD"
            tab_busSol = array2table(rm_bus, "VariableNames","P", "RowNames",sv_bus);
            tab_cub    = array2table(rm_cub, "VariableNames","P", "RowNames",sv_cub);
    end

    % Branches: flows at both ends (from = From, to = To of the branch table), as power and
    % current flowing into the branch, the negative of the branch-end rows of tab_cub; NaN
    % in ELD, which ignores the branches
    n_br = height(tab_branch);
    cm_S = nan(n_br,2);
    cm_I = nan(n_br,2);
    for k = 1:n_br
        sv_end = sv_br(k) + "_" + [tab_branch.From(k), tab_branch.To(k)];
        for i_end = 1:2
            switch s_method
                case "AC OPF"
                    v = sol.(sv_end(i_end));
                    cm_S(k,i_end) = -(v(1) + 1j*v(2));
                    cm_I(k,i_end) = -(v(3) + 1j*v(4));
                case "DC OPF"
                    cm_S(k,i_end) = -sol.(sv_end(i_end));
            end
        end
    end
    if s_method == "AC OPF"
        tab_branchSol = table(real(cm_S(:,1)), imag(cm_S(:,1)), real(cm_S(:,2)), imag(cm_S(:,2)), ...
                              cm_I(:,1), cm_I(:,2), real(sum(cm_S,2)), imag(sum(cm_S,2)), ...
                              'VariableNames', ["Pfrom","Qfrom","Pto","Qto","Ifrom","Ito","Ploss","Qloss"], ...
                              'RowNames', sv_br);
    else
        tab_branchSol = table(real(cm_S(:,1)), real(cm_S(:,2)), real(sum(cm_S,2)), ...
                              'VariableNames', ["Pfrom","Pto","Ploss"], ...
                              'RowNames', sv_br);
    end

    sct_solution = struct("tab_bus", tab_busSol, "tab_cub", tab_cub, "tab_branch", tab_branchSol, ...
        "r_cost", fval, "lambda", lambda, "OPFprob", prob);

    % keep the bus voltages of a solved AC OPF for the next warm start
    if s_method == "AC OPF" && flag > 0
        obj.sv_warmBus = sv_bus;
        obj.rm_Vwarm   = [tab_busSol.Varg, tab_busSol.V];
    end
end
