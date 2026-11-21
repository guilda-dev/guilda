function [sct_state, sv_bus, sv_comp] = diagram_state(obj, cm_V, cm_S)
% State of GraphNetDiagram from bus voltages and component powers in the order of the result tables.
%
% cm_V holds the bus voltage phasors in the rows of tab_bus and cm_S the injected powers
% P + jQ in the rows of tab_cub (the branch-end rows are not read), one column per sample.
% The state follows the a_Bus and a_Component order of sct_network; the current of a
% component is conj(S / V) at the voltage of its bus. Called by plot_lmp and plot_iteration.
    arguments (Input)
        obj
        cm_V double  % [pu] Bus voltage phasors: one row per row of tab_bus, one column per sample.
        cm_S double  % [pu] Injected powers P + jQ: one row per row of tab_cub, one column per sample.
    end
    arguments (Output)
        sct_state  % State of GraphNetDiagram: rv_t (1:n), cm_Vbus, cm_Icomp.
        sv_bus     % Bus tags in the a_Bus order of sct_network.
        sv_comp    % Component tags in the order of cm_Icomp.
    end
    a_bus   = reshape(obj.sct_network.a_Bus, [], 1);
    sv_bus  = string(cellfun(@(b) b.s_tag, a_bus, "UniformOutput", false));
    [~, iv_bus] = ismember(sv_bus, string(obj.tab_bus.Properties.RowNames));
    cm_Vbus = cm_V(iv_bus, :);
    sv_comp = strings(0, 1);
    iv_of   = zeros(0, 1);
    for i = 1:numel(a_bus)
        sv_c    = reshape(string(cellfun(@(c) c.s_tag, a_bus{i}.a_Component, "UniformOutput", false)), [], 1);
        sv_comp = [sv_comp; sv_c]; %#ok<AGROW>
        iv_of   = [iv_of; repmat(i, numel(sv_c), 1)]; %#ok<AGROW>
    end
    [~, iv_cub] = ismember(sv_comp, string(obj.tab_cub.Properties.RowNames));
    sct_state = struct("rv_t", 1:size(cm_V, 2), "cm_Vbus", cm_Vbus, ...
                       "cm_Icomp", conj(cm_S(iv_cub, :) ./ cm_Vbus(iv_of, :)));
end
