function [sv_bv, sv_bvBus, iv_kind] = bus_variables(obj, k)
% Bus variables of the DAE of section k: their names, buses and kinds, as get_ss orders
% them (every bus for the first kind, then for the second): kind 1 is theta (Vre for Port
% "I"), kind 2 the second variable (rho for "PQ", V for "PI", Vim for "I"). Used by
% plot_reduced_matrix and plot_contribution.
    arguments (Input)
        obj ResultLIN          % The result (of the network).
        k (1,1) double         % Section.
    end
    arguments (Output)
        sv_bv (:,1) string     % Names of the bus variables (StateName of get_ss("DAE")).
        sv_bvBus (:,1) string  % Bus tag of each.
        iv_kind (:,1) double   % 1 or 2.
    end
    sv_dae = obj.get_ss("DAE", Index=k, Format="struct").StateName;
    lv_bv = ~ismember(sv_dae, obj.tab_variable.Label);
    sv_bv = sv_dae(lv_bv);
    sv_bvBus = state_owner(obj, sv_dae);
    sv_bvBus = sv_bvBus(lv_bv);
    iv_kind = 1 + ((1:numel(sv_bv))' > numel(sv_bv)/2);
end
