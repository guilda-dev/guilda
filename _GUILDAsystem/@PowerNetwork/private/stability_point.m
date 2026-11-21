function rv_point = stability_point(sct_ctx, rv_u, s_point)
% Point of get_sys (rows x, Vre, Vim, u, uc of the variable map) at the set points rv_u, without writing the network.
%
% The power flow table sct_ctx.tab_pf (get_pf_condition of the buses, the slack bus of the
% stability-constrained OPF, the voltages and powers of the OPF solution, the start V0 and
% Varg0 at that solution) gets the set points rv_u: P of the generators sct_ctx.tab_u
% (Kind "P", the P of the component in the snapshot buses sct_ctx.a_bus and the sum P of its
% bus) and V of the buses (Kind "V"). SolverPF solves it with a solver of its own (not
% net.solver_PF). The bus powers are split among the components by tools.distribute_power
% on the snapshot buses, and the states and inputs come from get_equilibrium of the
% components, of their local controllers (get_equilibrium_at, with the voltage, the input
% and the state of the component; an input observed on the component, iv_obsX / iv_obsY,
% takes the value of the component at the point, as in the operating points of the
% continuation power flow) and of the global controllers, which return values and store nothing. A
% power flow that does not converge or a get_equilibrium that stops raises
% GUILDA:PowerNetwork:StabilityPointFailed, naming the point s_point. Called by
% calculate_optimal_powerflow and stability_gradient.
    arguments (Input)
        sct_ctx (1,1) struct   % Data of the stability-constrained OPF (see calculate_optimal_powerflow).
        rv_u (:,1) double      % [pu] Set points in the order of sct_ctx.tab_u.
        s_point (1,1) string   % Name of the point for the error message.
    end
    arguments (Output)
        rv_point (:,1) double  % Point of get_sys.
    end
    tab   = sct_ctx.tab_pf;
    a_bus = sct_ctx.a_bus;
    tab_u = sct_ctx.tab_u;
    for k = 1:height(tab_u)
        i = tab_u.Bus(k);
        if tab_u.Kind(k) == "P"
            a_bus{i}.a_Component{tab_u.Component(k)}.tab_parameter.powerflow.P = rv_u(k);
            tab.P(i) = sum(cellfun(@(c) c.tab_parameter.powerflow.P, a_bus{i}.a_Component));
        else
            tab.V(i) = rv_u(k);
        end
    end
    [cv_V, flag, output] = SolverPF().solve(sct_ctx.cm_Y, tab, sct_ctx.sct_pf);
    if flag ~= 1
        error(msg("GUILDA:PowerNetwork:StabilityPointFailed", s_point, output.message))
    end
    cv_S = cv_V .* conj(sct_ctx.cm_Y * cv_V);

    rv_point = zeros(sct_ctx.n_point, 1);
    rv_point(sct_ctx.iv_Vre) = real(cv_V);
    rv_point(sct_ctx.iv_Vim) = imag(cv_V);
    try
        for i = 1:numel(a_bus)
            rm_PQ = tools.distribute_power(a_bus{i}, real(cv_S(i)), imag(cv_S(i)), "baseMVA");
            for j = 1:numel(a_bus{i}.a_Component)
                c_unit = sct_ctx.c_unit{i}{j};      % the component, then its local controllers (depth first)
                c_I = conj((rm_PQ(j,1) + 1j*rm_PQ(j,2)) / cv_V(i));
                comp = c_unit{1,1};
                [rv_x, rv_uComp] = comp.get_equilibrium(cv_V(i), c_I, rm_PQ(j,1), rm_PQ(j,2));
                rv_x = reshape(rv_x, [], 1);
                rv_point(c_unit{1,2}) = rv_x;
                rv_point(c_unit{1,3}) = rv_uComp;
                rv_y = zeros(0,1);
                if size(c_unit, 1) > 1 && ~isempty(comp.sv_y)
                    rv_y = reshape(comp.f_Y(0, rv_x, [real(cv_V(i)); imag(cv_V(i))]), [], 1);
                end
                for m = 2:size(c_unit, 1)
                    con = c_unit{m,1};
                    [rv_xc, rv_uc] = con.get_equilibrium_at(cv_V(i), rv_uComp, rv_x);
                    rv_uc = reshape(rv_uc, [], 1);
                    lv_Y = con.iv_obsY > 0;     % inputs observed on the component take its values at the point
                    lv_X = con.iv_obsX > 0;
                    rv_uc(lv_Y) = rv_y(con.iv_obsY(lv_Y));
                    rv_uc(lv_X) = rv_x(con.iv_obsX(lv_X));
                    rv_point(c_unit{m,2}) = rv_xc;
                    rv_point(c_unit{m,3}) = rv_uc;
                end
            end
        end
        for k = 1:size(sct_ctx.c_gc, 1)
            [rv_point(sct_ctx.c_gc{k,2}), rv_point(sct_ctx.c_gc{k,3})] = sct_ctx.c_gc{k,1}.get_equilibrium();
        end
    catch ME
        error(msg("GUILDA:PowerNetwork:StabilityPointFailed", s_point, ME.message))
    end
end
