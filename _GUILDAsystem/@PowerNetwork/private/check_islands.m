function check_islands(sct_dae, sct_event, tab_phase)
% Each set of open branches must leave every bus connected to a component: nothing sets
% the voltages of a part of the network without components (with no shunt either, the
% DAE is singular). Checked for all phases before the integration starts; stops with
% GUILDA:PowerNetwork:OpenBranchIsland.
    arguments (Input)
        sct_dae   (1,1) struct  % Data of the run (im_branchBus, c_comp, sv_bus, sv_branch).
        sct_event (:,1) struct  % Phases of the run (iv_openBranch).
        tab_phase table         % output.phases (t1, t2 of each phase).
    end
    n_bus   = numel(sct_dae.sv_bus);
    lv_comp = false(n_bus, 1);
    lv_comp(cellfun(@(b) b.i_bus, sct_dae.c_comp)) = true;
    im_bus  = sct_dae.im_branchBus;
    for tp = 1:numel(sct_event)
        iv_open = sct_event(tp).iv_openBranch;
        if isempty(iv_open)
            continue
        end
        lv_on   = true(size(im_bus,1), 1);
        lv_on(iv_open) = false;
        G       = graph(im_bus(lv_on,1), im_bus(lv_on,2), [], n_bus);
        iv_part = conncomp(G);
        lv_dead = ~ismember(iv_part, iv_part(lv_comp(:).'));
        if any(lv_dead)
            error(msg("GUILDA:PowerNetwork:OpenBranchIsland", num2str(tp), num2str(tab_phase{tp,"t1"}), ...
                      num2str(tab_phase{tp,"t2"}), char(join(sct_dae.sv_branch(iv_open), ", ")), ...
                      char(join(sct_dae.sv_bus(lv_dead), ", "))));
        end
    end
end
