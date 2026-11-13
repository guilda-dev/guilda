function sol = struct_result(sct_sol, sct_dae, sct_event, tab_phase, s_scenario)
% The first output of simulate with Format="struct": the model hierarchy with tables.
%
% sol.t is the time of every row of every table (no Time column in the tables). Each bus
% has the tables V (Vre, Vim), I (Ire, Iim: the current injected into the network) and
% P, Q (P + jQ = V conj(I)); each component x (states), u (inputs) and I (the current it
% injects, f_I evaluated at each time; 0 while tripped); each local controller x and u
% (its inputs uc), nested as in the model; each global controller x and u (one column
% <input>_<unit tag> per controlled unit). The states and inputs of a tripped component
% or global controller are NaN. The outputs y are not computed.
    arguments (Input)
        sct_sol    (1,1) struct  % Trajectories of SolverODE.solve (rv_t, rm_variable, rm_I, rv_phase).
        sct_dae    (1,1) struct  % Data of the run (build_simulation_data).
        sct_event  (:,1) struct  % Phases of the run (the trips of each phase).
        tab_phase  table         % output.phases.
        s_scenario (1,1) string  % Tag of the scenario.
    end
    arguments (Output)
        sol (1,1) struct  % t, s_tag, phase, tab_variable, a_Bus, a_GlobalController.
    end
    tab   = sct_dae.tab_variable;
    n_var = nnz(tab.Role == "variable");
    rv_t  = sct_sol.rv_t(:);
    n_t   = numel(rv_t);
    X     = sct_sol.rm_variable;
    rv_phase = sct_sol.rv_phase(:);

    % Trips of each time; time from the start of its phase (as the solver)
    n_comp = numel(sct_dae.c_comp);
    n_gc   = numel(sct_dae.c_gc);
    lm_compOff = false(n_t, n_comp);
    lm_gcOff   = false(n_t, n_gc);
    rv_tp = zeros(n_t, 1);
    for p = 1:numel(sct_event)
        lv_p = rv_phase == p;
        lm_compOff(lv_p, sct_event(p).iv_tripComp) = true;
        lm_gcOff(lv_p, sct_event(p).iv_tripGC)     = true;
        rv_tp(lv_p) = rv_t(lv_p) - sct_event(p).t1;
    end

    sol = struct();
    sol.t = rv_t;
    sol.s_tag = s_scenario;
    sol.phase = tab_phase;
    sol.tab_variable = tab(1:n_var, :);

    % Buses
    iv_V = find(ismember(tab.Kind, ["Vre","Vim"]));      % [Vre; Vim] of each bus, in bus order
    n_bus = numel(sct_dae.sv_bus);
    sol.a_Bus = cell(n_bus, 1);
    for i = 1:n_bus
        V = X(:, iv_V(2*i - 1 + (0:1)));
        I = sct_sol.rm_I(:, 2*i - 1 + (0:1));
        S = complex(V(:,1), V(:,2)) .* conj(complex(I(:,1), I(:,2)));
        sb = struct();
        sb.s_tag = sct_dae.sv_bus(i);
        sb.V = array2table(V, "VariableNames", ["Vre","Vim"]);
        sb.I = array2table(I, "VariableNames", ["Ire","Iim"]);
        sb.P = array2table(real(S), "VariableNames", "P");
        sb.Q = array2table(imag(S), "VariableNames", "Q");
        sb.a_Component = cell(0,1);
        sol.a_Bus{i} = sb;
    end

    % Components with their local controllers (nested)
    for j = 1:n_comp
        b  = sct_dae.c_comp{j};
        lv_off = lm_compOff(:, j);
        Xb = X(:, b.iv_x);
        Ub = X(:, b.iv_u);
        Ub(lv_off, :) = NaN;
        Vb = X(:, iv_V(2*b.i_bus - 1 + (0:1)));
        Ib = zeros(n_t, 2);
        for k = find(~lv_off).'
            Ik = b.f_I(rv_tp(k), Xb(k,:).', Vb(k,:).', Ub(k,:).');
            Ib(k,:) = [real(Ik), imag(Ik)];
        end
        sc = struct();
        sc.s_tag = b.s_tag;
        sc.x = block_table(Xb, tab.Name(b.iv_x), n_t);
        sc.u = block_table(Ub, tab.Name(b.iv_u), n_t);
        sc.I = array2table(Ib, "VariableNames", ["Ire","Iim"]);
        sc.a_LocalController = local_controllers(sct_dae, b.iv_lc, 0, X, tab, n_t);
        sol.a_Bus{b.i_bus}.a_Component{end+1,1} = sc;
    end

    % Global controllers
    sol.a_GlobalController = cell(n_gc, 1);
    for k = 1:n_gc
        b  = sct_dae.c_gc{k};
        lv_off = lm_gcOff(:, k);
        Ub = X(:, b.iv_u);
        Ub(lv_off, :) = NaN;
        sv_u = erase(tab.Label(b.iv_u), "_" + b.s_tag + textBoundary("end"));
        sg = struct();
        sg.s_tag = b.s_tag;
        sg.x = block_table(X(:, b.iv_x), tab.Name(b.iv_x), n_t);
        sg.u = block_table(Ub, sv_u, n_t);
        sol.a_GlobalController{k} = sg;
    end
end


function c_lc = local_controllers(sct_dae, iv_lc, i_parent, X, tab, n_t)
% The local controllers among iv_lc whose parent is i_parent (0: the component), each with
% its own local controllers
    arguments (Input)
        sct_dae  (1,1) struct
        iv_lc    (:,1) double  % Local controllers of the component (positions in c_lc).
        i_parent (1,1) double  % Parent (position in c_lc; 0: the component).
        X        double        % rm_variable.
        tab      table         % Variable map.
        n_t      (1,1) double  % Number of times.
    end
    arguments (Output)
        c_lc (:,1) cell  % One struct per local controller: s_tag, x, u, a_LocalController.
    end
    c_lc = cell(0,1);
    for k = reshape(iv_lc, 1, [])
        b = sct_dae.c_lc{k};
        if b.i_parent ~= i_parent
            continue
        end
        sl = struct();
        sl.s_tag = b.s_tag;
        sl.x = block_table(X(:, b.iv_x), tab.Name(b.iv_x), n_t);
        sl.u = block_table(X(:, b.iv_u), tab.Name(b.iv_u), n_t);
        sl.a_LocalController = local_controllers(sct_dae, iv_lc, k, X, tab, n_t);
        c_lc{end+1,1} = sl; %#ok<AGROW>
    end
end

function T = block_table(M, sv_name, n_t)
% Table of n_t rows with one variable per name (no variable without names)
    arguments (Input)
        M        double       % Values: n_t x numel(sv_name).
        sv_name  (:,1) string  % Variable names.
        n_t      (1,1) double  % Number of rows.
    end
    arguments (Output)
        T table
    end
    if isempty(sv_name)
        T = table('Size', [n_t, 0], 'VariableTypes', strings(1,0));
    else
        T = array2table(M, "VariableNames", sv_name);
    end
end
