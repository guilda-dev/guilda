function sct = build_index(net)
% Positions of a run in the DAE vector and what each evaluation reads, from the variable map.
%
% The DAE vector of the simulation is z = [x; V; I; u; uc]: the variables of
% net.get_variable_map() in its order (x, Vre/Vim, u, uc), with the bus currents I (Ire, Iim
% of each bus, not in the map) after the voltages. The outputs y and yc are not variables:
% each evaluation computes them into the signal vector s (the rows y, yc of the map). The
% inputs are given by the connection map: res = z_in - (e + S_sig*s + S_var*z), where e
% holds the equilibrium of the inputs without another source. Nothing is written to the
% model objects. Stops with GUILDA:SolverODE:Stale when net.initialize() is needed, with
% GUILDA:SolverODE:ForeignControlledUnit for a global controller whose unit left the
% network, and with GUILDA:SolverODE:GconNoTarget for an output of a global controller
% that drives no input. Called by solve.
    arguments (Input)
        net  % Network of the run.
    end
    arguments (Output)
        sct (1,1) struct  % Index data of the run (merged into ctx by solve).
    end
    check_network(net);

    [tab, ~, ~, tab_c] = net.get_variable_map();
    a_bus = net.a_Bus;
    a_gc  = net.a_GlobalController;
    n_bus = numel(a_bus);

    % Positions in z of the variables, and in s of the signals
    lv_var = tab.Role == "variable";
    n_var  = nnz(lv_var);                     % the variables are the leading rows
    n_xV   = nnz(ismember(tab.Kind, ["x","Vre","Vim"]));
    iv_z   = zeros(height(tab),1);
    iv_z(1:n_xV)       = 1:n_xV;
    iv_z(n_xV+1:n_var) = (n_xV+1:n_var) + 2*n_bus;
    iv_s   = zeros(height(tab),1);
    iv_s(n_var+1:end)  = 1:height(tab)-n_var;
    n_z    = n_var + 2*n_bus;
    n_s    = height(tab) - n_var;
    n_in   = n_var - n_xV;                    % u and uc
    iv_in  = (n_xV + 2*n_bus + 1 : n_z)';
    lv_V   = ismember(tab.Kind, ["Vre","Vim"]);
    iv_V   = iv_z(lv_V);
    iv_I   = n_xV + (1:2*n_bus)';

    sct = struct();
    sct.n_z   = n_z;
    sct.n_s   = n_s;
    sct.iv_V  = iv_V;
    sct.iv_I  = iv_I;
    sct.iv_in = iv_in;
    sct.iv_lin = iv_z(ismember(tab.Kind, ["x","Vre","Vim","u"]));   % the rows of ResultODE

    % Owner of each element of z (a trip or a fault removes the elements it owns)
    sv_bus = string(a_bus(:));
    sct.sv_owner = strings(n_z,1);
    sct.sv_owner(iv_z(lv_var)) = tab.Owner(lv_var);
    sct.sv_owner(iv_I) = repelem(sv_bus, 2);

    % Rows of each owner and kind
    rows = @(s_owner, s_kind) find(tab.Owner == s_owner & tab.Kind == s_kind);

    % Equilibrium of z and mass matrix
    rv_z0 = zeros(n_z,1);
    rv_z0(iv_V) = tools.vcellfun(@(b) [real(b.c_Vequilibrium); imag(b.c_Vequilibrium)], a_bus);
    rv_z0(iv_I) = tools.vcellfun(@(b) [real(b.c_Iequilibrium); imag(b.c_Iequilibrium)], a_bus);
    c_M = cell(0,2);

    % Components and their local controllers (depth first)
    c_comp = tools.cellfun(@(b) b.a_Component, a_bus);
    iv_bus = repelem((1:n_bus)', cellfun(@numel, c_comp));
    c_comp = vertcat(cell(0,1), c_comp{:});
    sct.c_comp = cell(numel(c_comp),1);
    sct.c_lc   = cell(0,1);
    for j = 1:numel(c_comp)
        comp = c_comp{j};
        s_tag = string(comp.s_tag);
        st = struct("iv_x", iv_z(rows(s_tag,"x")), "iv_V", iv_V(2*iv_bus(j)-1 + (0:1)'), ...
                    "iv_u", iv_z(rows(s_tag,"u")), "iv_s", iv_s(rows(s_tag,"y")), "l_y", false, ...
                    "f_dx", comp.f_dx, "f_I", comp.f_I, "f_Y", comp.f_Y, "f_JacobiDx", comp.f_JacobiDx, ...
                    "f_JacobiI", comp.f_JacobiI, "f_JacobiY", comp.f_JacobiY, "s_tag", s_tag, "iv_lc", zeros(0,1));
        st.comp = comp;               % not an argument of struct: Component overloads it
        rv_z0(st.iv_x) = comp.rv_Xequilibrium;
        rv_z0(st.iv_u) = comp.rv_Uequilibrium;
        c_M(end+1,:) = {st.iv_x, tools.read_mass(comp)}; %#ok<AGROW>

        c_LC = all_controllers(comp);
        for k = 1:numel(c_LC)
            con = c_LC{k};
            s_lc = string(con.s_tag);
            sl = struct("iv_x", iv_z(rows(s_lc,"x")), "iv_V", st.iv_V, "iv_u", iv_z(rows(s_lc,"uc")), ...
                        "iv_s", iv_s(rows(s_lc,"yc")), "f_dx", con.f_dx, "f_Y", con.f_Y, ...
                        "f_JacobiDx", con.f_JacobiDx, "f_JacobiY", con.f_JacobiY);
            sl.con = con;
            rv_z0(sl.iv_x) = con.rv_Xequilibrium;
            rv_z0(sl.iv_u) = con.rv_Uequilibrium;
            c_M(end+1,:) = {sl.iv_x, tools.read_mass(con)}; %#ok<AGROW>
            sct.c_lc{end+1,1} = sl;
            st.iv_lc(end+1,1) = numel(sct.c_lc);
        end
        sct.c_comp{j} = st;
    end

    % Global controllers: all bus voltages
    sct.c_gc = cell(numel(a_gc),1);
    for k = 1:numel(a_gc)
        gc = a_gc{k};
        s_gc = string(gc.s_tag);
        sg = struct("iv_x", iv_z(rows(s_gc,"x")), "iv_V", iv_V, "iv_u", iv_z(rows(s_gc,"uc")), ...
                    "iv_s", iv_s(rows(s_gc,"yc")), "f_dx", gc.f_dx, "f_Y", gc.f_Y, ...
                    "f_JacobiDx", gc.f_JacobiDx, "f_JacobiY", gc.f_JacobiY, "s_tag", s_gc);
        sg.gc = gc;
        rv_z0(sg.iv_x) = gc.rv_Xequilibrium;
        rv_z0(sg.iv_u) = gc.rv_Uequilibrium;
        c_M(end+1,:) = {sg.iv_x, tools.read_mass(gc)}; %#ok<AGROW>
        sct.c_gc{k} = sg;

        % Each output must drive an input (a local controller with that input may have
        % been removed since add_global_controller)
        lv_out = tab_c.Kind == "global" & ismember(tab_c.SourceIndex, rows(s_gc,"yc"));
        iv_none = setdiff(rows(s_gc,"yc"), tab_c.SourceIndex(lv_out));
        if ~isempty(iv_none)
            n_o = numel(gc.sv_y);
            m = iv_none(1) - min(rows(s_gc,"yc"));       % 0-based row among its outputs
            unit = gc.controlledUnits{floor(m/n_o)+1};
            error(msg("GUILDA:SolverODE:GconNoTarget", char(s_gc), char(gc.sv_y(mod(m,n_o)+1)), char(unit.s_tag)))
        end
    end
    sct.rv_z0 = rv_z0;
    sct.sv_comp = string(c_comp);
    sct.sv_gc   = string(a_gc(:));
    sct.sv_bus  = sv_bus;
    M = sparse(n_z, n_z);
    for p = 1:size(c_M,1)
        M(c_M{p,1}, c_M{p,1}) = c_M{p,2}; %#ok<SPRIX>
    end
    sct.rm_M = M;

    % Connections: e (equilibrium), S_sig (signal sources), S_var (state sources).
    % An input of a global controller that observes a component reads 0 while the
    % component is tripped (iv_gateIn: the input, iv_gateComp: the component)
    iv_tgt = tab_c.TargetIndex - n_xV;
    lv_eq  = tab_c.Kind == "equilibrium";
    rv_in0 = rv_z0(iv_in);
    sct.rv_e = zeros(n_in,1);
    sct.rv_e(iv_tgt(lv_eq)) = rv_in0(iv_tgt(lv_eq));
    lv_sig = ~lv_eq & tab.Role(max(tab_c.SourceIndex,1)) == "signal";
    lv_st  = ~lv_eq & ~lv_sig;
    sct.S_sig = sparse(iv_tgt(lv_sig), iv_s(tab_c.SourceIndex(lv_sig)), 1, n_in, n_s);
    sct.S_var = sparse(iv_tgt(lv_st), iv_z(tab_c.SourceIndex(lv_st)), 1, n_in, n_z);
    lv_gate = tab_c.Kind == "observe" & tab.Kind(tab_c.TargetIndex) == "uc" & ...
              ismember(tab.Owner(tab_c.TargetIndex), string(a_gc(:)));
    sv_comp = string(c_comp);
    [~, sct.iv_gateComp] = ismember(tab.Owner(tab_c.SourceIndex(lv_gate)), sv_comp);
    sct.iv_gateIn = iv_tgt(lv_gate);
    sct.S_sig0 = sct.S_sig;           % without the trips of a phase (set_phase in solve)
    sct.S_var0 = sct.S_var;

    % The outputs of a component are computed only when a connection reads them
    lv_read = full(any(sct.S_sig ~= 0, 1)).';
    for j = 1:numel(sct.c_comp)
        sct.c_comp{j}.l_y = any(lv_read(sct.c_comp{j}.iv_s));
    end
end


function check_network(net)
    % The checks before a run: units of the global controllers on the network, edited
    % inputs, and the stale tags of the network and its models
    a_gc = net.a_GlobalController;
    for k = 1:numel(a_gc)
        gcon = a_gc{k};
        for idx = 1:numel(gcon.controlledUnits)
            unit = gcon.controlledUnits{idx};
            if isempty(unit.a_Bus) || ~isequal(unit.a_Bus.a_PowerNetwork, net)
                error(msg("GUILDA:SolverODE:ForeignControlledUnit", char(gcon.s_tag), char(unit.s_tag), char(net.s_tag)))
            end
        end
    end
    if ~isempty(net.sct_stale.input)   % edited inputs: initialize(Method="FixedInput")
        sv_in = unique(net.sct_stale.input, "stable");
        error(msg("GUILDA:SolverODE:InputEdited", char(net.s_tag), char(join(sv_in(1:min(end,3)), "; "))))
    end
    sv = [net.sct_stale.powerflow; net.sct_stale.odefcn];   % messages of the stale tags
    for i = 1:numel(net.a_Bus)
        a_comp = net.a_Bus{i}.a_Component;
        for j = 1:numel(a_comp)
            a_obj = [a_comp(j); all_controllers(a_comp{j})];
            for k = 1:numel(a_obj)
                sv = [sv; a_obj{k}.sct_stale.equilibrium; a_obj{k}.sct_stale.odefcn]; %#ok<AGROW>
            end
        end
    end
    for k = 1:numel(a_gc)
        sv = [sv; a_gc{k}.sct_stale.equilibrium; a_gc{k}.sct_stale.odefcn]; %#ok<AGROW>
    end
    if ~isempty(sv)
        sv = unique(sv, "stable");
        s_reason = join(sv(1:min(end,3)), "; ");
        if numel(sv) > 3
            s_reason = s_reason + "; ...";
        end
        error(msg("GUILDA:SolverODE:Stale", char(net.s_tag), char(s_reason)))
    end
end

function list = all_controllers(parent)
    % Local controllers of parent, depth first (the order of the variable map)
    list = cell(0,1);
    for k = 1:numel(parent.a_LocalController)
        con  = parent.a_LocalController{k};
        list = [list; {con}; all_controllers(con)]; %#ok<AGROW>
    end
end
