function c_index = simulator_columns(tab, tab_out, sv_bus, c_component)
% c_index{i}: columns for the view odeResults of bus i: its voltage, and the component's
% own states, inputs (columns of rm_variable, rows of tab) and outputs (columns of
% rm_output, rows of tab_out); the states of its controllers are not included.
    arguments (Input)
        tab          table      % Rows x, Vre, Vim, u of the variable map (ResultODE.tab_variable).
        tab_out      table      % Rows y, yc of the variable map (ResultODE.tab_output).
        sv_bus       (:,1) string % Bus tags (ResultODE.sv_bus).
        c_component  (:,1) cell   % Component tags of each bus (ResultODE.c_component).
    end
    arguments (Output)
        c_index (:,1) cell  % Struct per bus: iv_V, c_x, c_u, c_y.
    end
    n_bus = numel(sv_bus);
    c_index = cell(n_bus,1);
    for i = 1:n_bus
        sv_comp = c_component{i};
        s = struct();
        s.iv_V = find((tab.Kind == "Vre" | tab.Kind == "Vim") & tab.Bus == sv_bus(i));
        s.c_x  = cell(1, numel(sv_comp));
        s.c_u  = cell(1, numel(sv_comp));
        s.c_y  = cell(1, numel(sv_comp));
        for j = 1:numel(sv_comp)
            s.c_x{j} = find(tab.Kind == "x" & tab.Owner == sv_comp(j));
            s.c_u{j} = find(tab.Kind == "u" & tab.Owner == sv_comp(j));
            s.c_y{j} = find(tab_out.Kind == "y" & tab_out.Owner == sv_comp(j));
        end
        c_index{i} = s;
    end
end
