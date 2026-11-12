function out = format_powerflow(s_format, tab_pf, f_result)
% First output of calculate_powerflow and initialize in the requested Format.
%
% | s_format          | out                                                              |
% |-------------------|------------------------------------------------------------------|
% | "V"               | complex bus voltages (column, bus order)                         |
% | "powerflow(mat)"  | n-by-4 complex double: V, I (phasors), P, Q (real); bus order    |
% | "powerflow(tab)"  | tab_pf (variables V, I, P, Q; row names = bus tags)              |
% | "GUILDAorigin"    | f_result(): the result object (ResultPF or ResultOPF)            |
%
% f_result is called only for "GUILDAorigin", so the other formats do not build the
% result object (nor the network snapshot it holds).
    arguments (Input)
        s_format (1,1) string            % Format option (one of the values above).
        tab_pf   table                   % Solution as in powerflow_table: V, I, P, Q; row names = bus tags.
        f_result function_handle         % Builds the result object for "GUILDAorigin".
    end
    arguments (Output)
        out                              % The first output in the requested form.
    end
    switch s_format
        case "V"
            out = tab_pf.V;
        case "powerflow(mat)"
            out = [tab_pf.V, tab_pf.I, complex(tab_pf.P), complex(tab_pf.Q)];
        case "powerflow(tab)"
            out = tab_pf;
        case "GUILDAorigin"
            out = f_result();
    end
end
