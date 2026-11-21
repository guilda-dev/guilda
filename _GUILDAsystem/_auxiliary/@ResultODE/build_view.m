function s = build_view(obj)
% odeResults from rv_t, rm_variable, rm_I, rm_Icomponent and rm_output (same layout as before
% the trajectory was stored in variable-map order, with the outputs Y and the current I of
% each component)
    s = struct();
    if isempty(obj.c_index)
        return
    end
    X = array2table(obj.rm_variable);
    I = array2table(obj.rm_I);
    Y = array2table(obj.rm_output);
    Ic = array2table(obj.rm_Icomponent);
    n_before = cumsum([0; cellfun(@numel, obj.c_component)]);   % components of the buses before bus i
    Vmap = obj.tab_variable.Name;
    Ymap = obj.tab_output.Name;

    s.t = obj.rv_t;
    for i = 1:numel(obj.c_index)
        idx = obj.c_index{i};

        s.Bus(i).Component = struct();
        for j = 1:numel(idx.c_x)
            sol_c_idx = X(:, idx.c_x{j});
            sol_c_idx.Properties.VariableNames = Vmap(idx.c_x{j});
            s.Bus(i).Component(j).X = sol_c_idx;

            sol_c_idx = X(:, idx.c_u{j});
            sol_c_idx.Properties.VariableNames = Vmap(idx.c_u{j});
            s.Bus(i).Component(j).U = sol_c_idx;

            sol_c_idx = Y(:, idx.c_y{j});
            sol_c_idx.Properties.VariableNames = Ymap(idx.c_y{j});
            s.Bus(i).Component(j).Y = sol_c_idx;

            sol_c_idx = Ic(:, 2*(n_before(i) + j) - 1 + (0:1));
            sol_c_idx.Properties.VariableNames = ["Ireal","Iimag"];
            s.Bus(i).Component(j).I = sol_c_idx;
        end

        sol_V_idx = X{:, idx.iv_V};
        sol_I_idx = I{:, [2*i-1,2*i]};
        sol_P_idx = array2table( sol_V_idx(:,1) .* sol_I_idx(:,1) + sol_V_idx(:,2) .* sol_I_idx(:,2) );
        sol_Q_idx = array2table( sol_V_idx(:,2) .* sol_I_idx(:,1) - sol_V_idx(:,1) .* sol_I_idx(:,2) );

        sol_V_idx = X(:, idx.iv_V);
        sol_I_idx = I(:, [2*i-1,2*i]);

        sol_V_idx.Properties.VariableNames = ["Vreal","Vimag"];
        sol_I_idx.Properties.VariableNames = ["Ireal","Iimag"];
        sol_P_idx.Properties.VariableNames = "P";
        sol_Q_idx.Properties.VariableNames = "Q";

        s.Bus(i).V  = sol_V_idx;
        s.Bus(i).I  = sol_I_idx;
        s.Bus(i).PQ = [sol_P_idx,sol_Q_idx];
    end
end
