function [tab_variable, rm_variable, cm_Icomponent] = operating_points(net, sct_network, sv_load, useInt, cm_Vbus, rm_x, rv_lambda, Ymat)
% Operating point of every step of the CPF path, in the rows of net.get_variable_map().
%
% At each step the bus injection V conj(Y V) is split to the components of the bus as
% initialize splits a power flow solution (tools.distribute_power on the network snapshot):
% each component starts from the power it injects in the CPF equations (pf_equation: its
% equilibrium power, scaled by (1 + lambda) on the buses of sv_load) and the free parts go
% to the components of the bus with Q = NaN (and to the first such component of the slack
% bus for P), so a PV bus switched to PQ by Limits "Q" keeps its fixed Q. With useInt the
% components inject their getCompPQ powers (all solved by the CPF), taken as they are.
% Each component then gets (x, u) from its own get_equilibrium(V, I, P, Q). With useInt, a
% component with CPF states takes x from rm_x and u = rv_Uequilibrium, the input of the CPF
% equations, so that dx = 0 holds for the state equations the CPF solves (a component
% without states keeps the u of get_equilibrium, which carries its scaled power). Its local
% controllers get x and uc from their
% get_equilibrium(V, u, x) (get_equilibrium_at, x the state of the component at the step)
% in the order of Component.set_equilibrium (depth first); a
% controller input observed on the component (iv_obsX / iv_obsY) takes the value of the
% component at the step. The states and inputs of the global controllers keep their
% equilibrium values. Only pure functions of the models are called: nothing is written.
% A model whose get_equilibrium stops at a step (e.g. a limit of its range) gives NaN for
% its values at that step.
    arguments (Input)
        net                         % Analysed network (only read).
        sct_network   (1,1) struct  % Snapshot struct(net, false) (its buses for tools.distribute_power).
        sv_load                     % Tags of the buses whose loads are scaled.
        useInt        (1,1) logical % True when the CPF used the internal states of the components.
        cm_Vbus       double        % [pu] Bus voltages at each step (n_bus x n_step).
        rm_x          double        % Full variable vector at each step (rows of comp.iv_CPFX with useInt).
        rv_lambda     double        % lambda at each step.
        Ymat                        % [pu] Bus admittance matrix (complex).
    end
    arguments (Output)
        tab_variable  table   % Rows x, Vre, Vim, u, uc of net.get_variable_map().
        rm_variable   double  % Values: row k at step k, column m the row m of tab_variable.
        cm_Icomponent double  % [pu] Current injected by each component (rows in network order) at each step.
    end
    tab = net.get_variable_map();
    tab_variable = tab(ismember(tab.Kind, ["x","Vre","Vim","u","uc"]), :);
    sv_key = string(tab_variable.Kind) + "|" + string(tab_variable.Owner) + "|" + string(tab_variable.Name) + "|" + string(tab_variable.Bus);

    a_bus  = net.a_Bus;
    n_bus  = numel(a_bus);
    n_step = numel(rv_lambda);
    n_comp = sum(cellfun(@(b) numel(b.a_Component), a_bus));
    rm_variable   = repmat(reshape(tab_variable.Equilibrium, 1, []), n_step, 1);   % global controllers keep these
    cm_Icomponent = complex(nan(n_comp, n_step));

    % columns of each block of values (found once)
    c_bus = cell(n_bus,1);
    for i = 1:n_bus
        s_bus  = string(a_bus{i}.s_tag);
        a_comp = a_bus{i}.a_Component;
        sct = struct("iv_V", col(sv_key, ["Vre";"Vim"], s_bus, ["Vre";"Vim"], s_bus), "c_comp", {cell(numel(a_comp),1)});
        for j = 1:numel(a_comp)
            comp = a_comp{j};
            s_c  = string(comp.s_tag);
            c_lc = cell(0,1);
            c_st = reshape(comp.a_LocalController, [], 1);
            while ~isempty(c_st)       % depth first, a nested controller after its parent
                con = c_st{1};
                lc = struct("iv_x", col(sv_key, "x", string(con.s_tag), con.sv_x, s_bus), ...
                            "iv_u", col(sv_key, "uc", string(con.s_tag), con.sv_u, s_bus));
                lc.con = con;           % struct(name, model) would call the struct method of the model
                c_lc{end+1,1} = lc; %#ok<AGROW>
                c_st = [reshape(con.a_LocalController, [], 1); c_st(2:end)];
            end
            blk = struct("iv_x", col(sv_key, "x", s_c, comp.sv_x, s_bus), ...
                "iv_u", col(sv_key, "u", s_c, comp.sv_u, s_bus), "c_lc", {c_lc}, ...
                "l_load", ismember(s_bus, sv_load) || useInt);
            blk.comp = comp;
            sct.c_comp{j} = blk;
        end
        c_bus{i} = sct;
    end

    for k = 1:n_step
        cv_V = cm_Vbus(:,k);
        cv_S = cv_V .* conj(Ymat * cv_V);
        r_scale = 1 + rv_lambda(k);
        i_c = 0;
        for i = 1:n_bus
            sct = c_bus{i};
            c_V = cv_V(i);
            rm_variable(k, sct.iv_V) = [real(c_V), imag(c_V)];
            n_c = numel(sct.c_comp);
            if n_c == 0
                continue
            end
            rv_Vpol = [abs(c_V); angle(c_V)];
            rm_PQ = zeros(n_c,2);
            for j = 1:n_c
                comp = sct.c_comp{j}.comp;
                x_cpf = zeros(0,1);
                if useInt
                    x_cpf = rm_x(comp.iv_CPFX,k);
                end
                rm_PQ(j,:) = reshape(comp.f_PQ2Bus(x_cpf, rv_Vpol, comp.rv_Uequilibrium), 1, []);
                if sct.c_comp{j}.l_load
                    rm_PQ(j,:) = rm_PQ(j,:) * r_scale;
                end
            end
            if ~useInt   % the free parts of the bus injection (slack P, Q of the generators)
                bus_k = sct_network.a_Bus{i};
                for j = 1:n_c
                    tab_pf = bus_k.a_Component{j}.tab_parameter.powerflow;
                    tab_pf.P = rm_PQ(j,1);
                    tab_pf.Q(~isnan(tab_pf.Q)) = rm_PQ(j,2);
                    bus_k.a_Component{j}.tab_parameter.powerflow = tab_pf;
                end
                rm_PQ = tools.distribute_power(bus_k, real(cv_S(i)), imag(cv_S(i)));
            end
            for j = 1:n_c
                i_c  = i_c + 1;
                blk  = sct.c_comp{j};
                comp = blk.comp;
                c_I  = conj((rm_PQ(j,1) + 1j*rm_PQ(j,2)) / c_V);
                cm_Icomponent(i_c,k) = c_I;
                try
                    [x, u] = comp.get_equilibrium(c_V, c_I, rm_PQ(j,1), rm_PQ(j,2));
                    x = reshape(x, [], 1);
                    u = reshape(u, [], 1);
                    if useInt && ~isempty(comp.iv_CPFX)   % the CPF state and the input of the CPF equations
                        x = rm_x(comp.iv_CPFX, k);
                        u = reshape(comp.rv_Uequilibrium, [], 1);
                    end
                catch
                    x = nan(numel(blk.iv_x),1);
                    u = nan(numel(blk.iv_u),1);
                end
                rm_variable(k, blk.iv_x) = x;
                rm_variable(k, blk.iv_u) = u;
                if isempty(blk.c_lc)
                    continue
                end
                rv_Vri = [real(c_V); imag(c_V)];
                y = zeros(0,1);
                if ~isempty(comp.sv_y) && all(isfinite(x))
                    y = reshape(comp.f_Y(0, x, rv_Vri), [], 1);
                end
                for m = 1:numel(blk.c_lc)
                    lc  = blk.c_lc{m};
                    con = lc.con;
                    try
                        [xc, uc] = con.get_equilibrium_at(c_V, u, x);
                        xc = reshape(xc, [], 1);
                        uc = reshape(uc, [], 1);
                        lv_Y = con.iv_obsY > 0;
                        lv_X = con.iv_obsX > 0;
                        if any(lv_Y)
                            uc(lv_Y) = y(con.iv_obsY(lv_Y));
                        end
                        uc(lv_X) = x(con.iv_obsX(lv_X));
                    catch
                        xc = nan(numel(lc.iv_x),1);
                        uc = nan(numel(lc.iv_u),1);
                    end
                    rm_variable(k, lc.iv_x) = xc;
                    rm_variable(k, lc.iv_u) = uc;
                end
            end
        end
    end

end


function iv = col(sv_key, s_kind, s_owner, sv_name, s_bus)
% Columns of rm_variable of the rows (Kind, Owner, Name, Bus) of one owner
    arguments (Input)
        sv_key  (:,1) string  % Keys "Kind|Owner|Name|Bus" of the rows of tab_variable.
        s_kind  (:,1) string  % Kind of the rows (one, or one per name).
        s_owner (1,1) string  % Owner (tag of the model or bus).
        sv_name               % Names of the rows.
        s_bus   (1,1) string  % Bus of the owner.
    end
    arguments (Output)
        iv (1,:) double  % Columns, in the order of sv_name.
    end
    sv_name = reshape(string(sv_name), [], 1);
    [lv, iv] = ismember(s_kind + "|" + s_owner + "|" + sv_name + "|" + s_bus, sv_key);
    iv = reshape(iv(lv), 1, []);
end
