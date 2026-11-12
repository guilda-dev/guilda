function tab = violation_table(sct_network, tab_bus, tab_branch, r_tol)
% Operating limits (tab_parameter.operation) that the power flow solution violates.
%
% One row per violated limit: the solution value is beyond the limit by more than r_tol.
% NaN and infinite limits are none. The limits are read from the network snapshot.
% Checked limits and values:
%
% - Bus: Vmin, Vmax on V.
% - Component: Pmin, Pmax on P and Qmin, Qmax on Q, the powers that initialize would
%   give it (tools.distribute_power with "baseMVA", as Bus.set_equilibrium by default:
%   tab_parameter.powerflow, the slack remainder and the split of the bus Q among the
%   components with Q = NaN).
% - Branch: Pmax on the larger |P|, Qmax on the larger |Q|, Smax on the larger |S| and
%   Imax on the larger |I| of the two ends, Vargmax on |Varg_from - Varg_to|.
    arguments (Input)
        sct_network struct      % Snapshot of the network (struct(net, false)), buses in tab_bus order.
        tab_bus    table        % tab_bus of the ResultPF.
        tab_branch table        % tab_branch of the ResultPF (rows in the order of the branches of the snapshot).
        r_tol      (1,1) double % [pu, rad] Excess below which a limit counts as met.
    end
    arguments (Output)
        tab table               % Columns Class, Object, Limit, Value, Bound, Excess (see ResultPF.tab_violation).
    end
    c_row = cell(0, 4);      % {Class, Object, Limit, [Value, Bound]}

    a_Bus = sct_network.a_Bus;
    for i_bus = 1:numel(a_Bus)
        bus = a_Bus{i_bus};
        ope = bus.tab_parameter.operation;
        c_row = check(c_row, "Bus", string(bus.s_tag), tab_bus.V(i_bus), ope, "V", r_tol);
        a_Com = bus.a_Component;
        if isempty(a_Com)
            continue
        end
        rm_PQ = tools.distribute_power(bus, tab_bus.P(i_bus), tab_bus.Q(i_bus), "baseMVA");
        for i_com = 1:numel(a_Com)
            com = a_Com{i_com};
            ope = com.tab_parameter.operation;
            c_row = check(c_row, "Component", string(com.s_tag), rm_PQ(i_com,1), ope, "P", r_tol);
            c_row = check(c_row, "Component", string(com.s_tag), rm_PQ(i_com,2), ope, "Q", r_tol);
        end
    end

    sv_bus = string(tab_bus.Properties.RowNames);
    a_Branch = sct_network.a_Branch;
    for i_br = 1:numel(a_Branch)
        br  = a_Branch{i_br};
        ope = br.tab_parameter.operation;
        s_br = string(br.s_tag);
        rr  = tab_branch(i_br, :);
        cv_S = [rr.Pfrom + 1j*rr.Qfrom, rr.Pto + 1j*rr.Qto];
        iv_end = bus_index(br.a_Bus, sv_bus);
        r_dVarg = abs(tab_bus.Varg(iv_end(1)) - tab_bus.Varg(iv_end(2)));
        c_row = check_max(c_row, s_br, "Pmax",    max(abs(real(cv_S))), ope.Pmax, r_tol);
        c_row = check_max(c_row, s_br, "Qmax",    max(abs(imag(cv_S))), ope.Qmax, r_tol);
        c_row = check_max(c_row, s_br, "Smax",    max(abs(cv_S)), ope.Smax, r_tol);
        c_row = check_max(c_row, s_br, "Imax",    max(abs([rr.Ifrom, rr.Ito])), ope.Imax, r_tol);
        c_row = check_max(c_row, s_br, "Vargmax", r_dVarg, ope.Vargmax, r_tol);
    end

    tab = rows_to_table(c_row);
end


function c_row = check(c_row, s_class, s_obj, r_val, ope, s_quantity, r_tol)
% Lower and upper limit <quantity>min / <quantity>max of ope
    r_min = ope.(s_quantity + "min");
    r_max = ope.(s_quantity + "max");
    if r_val < r_min - r_tol
        c_row(end+1,:) = {s_class, s_obj, s_quantity + "min", [r_val, r_min]};
    end
    if r_val > r_max + r_tol
        c_row(end+1,:) = {s_class, s_obj, s_quantity + "max", [r_val, r_max]};
    end
end


function c_row = check_max(c_row, s_obj, s_limit, r_val, r_max, r_tol)
% Upper limit of a branch (NaN or Inf: none)
    if ~isnan(r_max) && r_val > r_max + r_tol
        c_row(end+1,:) = {"Branch", s_obj, s_limit, [r_val, r_max]};
    end
end
