function [sct_sol, sct_dae] = result_data(net, c_phase)
% Inputs of the ResultODE constructor from the network and the phases of a run (temporary).
%
% sct_sol holds the trajectories of the phases (SolverODE.phase_result); sct_dae the
% variable map and, per block (component, local controller, global controller), the rows
% of its states, inputs and outputs and its output function f_Y. Step S5 of
% notes/simulate-redesign.md moves the collection to net.build_simulation_data and
% removes this function.
    arguments (Input)
        net               % Network of the run.
        c_phase  cell     % Result of each phase (phase_result: t, x, i).
    end
    arguments (Output)
        sct_sol  (1,1) struct  % rv_t, rm_variable (all variable rows: x, Vre, Vim, u, uc), rm_I, rv_phase.
        sct_dae  (1,1) struct  % tab_variable (the whole variable map), c_comp, c_lc, c_gc.
    end
    tab   = net.get_variable_map();
    a_bus = net.a_Bus;
    n_var = nnz(tab.Role == "variable");

    sol = reshape(c_phase, [], 1);
    sct_sol = struct();
    sct_sol.rv_t        = cell2mat([{zeros(0,1)}; cellfun(@(T) T.t, sol, 'UniformOutput', false)]);
    sct_sol.rm_variable = cell2mat([{zeros(0,n_var)}; cellfun(@(T) T.x, sol, 'UniformOutput', false)]);
    sct_sol.rm_I        = cell2mat([{zeros(0,2*numel(a_bus))}; cellfun(@(T) T.i, sol, 'UniformOutput', false)]);
    sct_sol.rv_phase    = repelem((1:numel(sol)).', cellfun(@(T) numel(T.t), sol));

    rows = @(s_owner, s_kind) find(tab.Owner == s_owner & tab.Kind == s_kind);
    sct_dae = struct("tab_variable", tab);
    sct_dae.c_comp = cell(0,1);
    sct_dae.c_lc   = cell(0,1);
    for i = 1:numel(a_bus)
        a_comp = a_bus{i}.a_Component;
        for j = 1:numel(a_comp)
            comp = a_comp{j};
            s_tag = string(comp.s_tag);
            sct_dae.c_comp{end+1,1} = struct("iv_x", rows(s_tag,"x"), "iv_u", rows(s_tag,"u"), ...
                "iv_y", rows(s_tag,"y"), "i_bus", i, "f_Y", comp.f_Y, "s_tag", s_tag);
            c_LC = all_controllers(comp);
            for k = 1:numel(c_LC)
                s_lc = string(c_LC{k}.s_tag);
                sct_dae.c_lc{end+1,1} = struct("iv_x", rows(s_lc,"x"), "iv_u", rows(s_lc,"uc"), ...
                    "iv_y", rows(s_lc,"yc"), "i_bus", i, "i_comp", numel(sct_dae.c_comp), ...
                    "f_Y", c_LC{k}.f_Y, "s_tag", s_lc);
            end
        end
    end
    a_gc = net.a_GlobalController;
    sct_dae.c_gc = cell(numel(a_gc),1);
    for k = 1:numel(a_gc)
        s_gc = string(a_gc{k}.s_tag);
        sct_dae.c_gc{k} = struct("iv_x", rows(s_gc,"x"), "iv_u", rows(s_gc,"uc"), ...
            "iv_y", rows(s_gc,"yc"), "f_Y", a_gc{k}.f_Y, "s_tag", s_gc);
    end
end


function list = all_controllers(parent)
% Local controllers of parent, depth first (the order of the variable map)
    arguments (Input)
        parent  % Component or local controller.
    end
    arguments (Output)
        list (:,1) cell  % Its local controllers and theirs.
    end
    list = cell(0,1);
    for k = 1:numel(parent.a_LocalController)
        con  = parent.a_LocalController{k};
        list = [list; {con}; all_controllers(con)]; %#ok<AGROW>
    end
end
