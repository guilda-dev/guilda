function rm_output = output_trajectory(sct_sol, sct_dae)
% Outputs y, yc at each time of the trajectory, from the output functions of the blocks.
%
% A component is evaluated as f_Y(t, x, V), a local controller as f_Y(t, x, V, u) and a
% global controller as f_Y(t, x, V_all, u), with t the time from the start of the phase
% (as the solver), V the voltage [Vre; Vim] of the bus of the block and V_all those of
% every bus. The columns follow the rows y, yc of the variable map. The outputs of a
% block whose states are NaN (a tripped unit) are NaN.
    arguments (Input)
        sct_sol (1,1) struct  % rv_t, rm_variable (variable rows of the map), rv_phase.
        sct_dae (1,1) struct  % tab_variable and the blocks c_comp, c_lc, c_gc.
    end
    arguments (Output)
        rm_output double  % Outputs: one row per time, one column per row y, yc of the map.
    end
    tab    = sct_dae.tab_variable;
    iv_out = find(ismember(tab.Kind, ["y","yc"]));
    n_t    = numel(sct_sol.rv_t);
    rm_output = zeros(n_t, numel(iv_out));
    if n_t == 0 || isempty(iv_out)
        return
    end

    % Time from the start of the phase
    rv_phase = sct_sol.rv_phase(:);
    [~, iv_first] = unique(rv_phase, "first");
    rv_start = zeros(max(rv_phase), 1);
    rv_start(rv_phase(iv_first)) = sct_sol.rv_t(iv_first);
    rv_tp = sct_sol.rv_t(:) - rv_start(rv_phase);

    X     = sct_sol.rm_variable;          % columns = rows of the map (variables lead)
    iv_V  = find(ismember(tab.Kind, ["Vre","Vim"]));     % [Vre; Vim] of each bus, in bus order
    c_blk = {sct_dae.c_comp, 1; sct_dae.c_lc, 2; sct_dae.c_gc, 3};
    for p = 1:size(c_blk,1)
        c_b = c_blk{p,1};
        for m = 1:numel(c_b)
            b = c_b{m};
            if isempty(b.iv_y)
                continue
            end
            [~, iv_col] = ismember(b.iv_y, iv_out);
            if c_blk{p,2} == 3
                iv_Vb = iv_V;
            else
                iv_Vb = iv_V(2*b.i_bus - 1 + (0:1));
            end
            Xb = X(:, b.iv_x);
            Vb = X(:, iv_Vb);
            Ub = X(:, b.iv_u);
            Y  = NaN(n_t, numel(iv_col));
            lv_on = ~any(isnan(Xb), 2);
            for k = find(lv_on).'
                switch c_blk{p,2}
                    case 1
                        Y(k,:) = b.f_Y(rv_tp(k), Xb(k,:).', Vb(k,:).');
                    otherwise
                        Y(k,:) = b.f_Y(rv_tp(k), Xb(k,:).', Vb(k,:).', Ub(k,:).');
                end
            end
            rm_output(:, iv_col) = Y;
        end
    end
end
