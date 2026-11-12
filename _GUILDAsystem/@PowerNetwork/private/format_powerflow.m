function out = format_powerflow(s_format, sv_bus, rm_pf, f_result)
% First output of calculate_powerflow and initialize in the requested Format.
%
% | s_format          | out                                                              |
% |-------------------|------------------------------------------------------------------|
% | "V"               | rm_pf(:,1): complex bus voltages (column, bus order)             |
% | "powerflow(mat)"  | rm_pf: n-by-4 complex double V, I, P, Q (bus order)              |
% | "powerflow(tab)"  | the same as a table (powerflow_table; row names = sv_bus)        |
% | "GUILDAorigin"    | f_result(): the result object (ResultPF or ResultOPF)            |
%
% Only "powerflow(tab)" builds a table and only "GUILDAorigin" calls f_result, so the
% other formats build neither the table nor the result object and its snapshot.
    arguments (Input)
        s_format (1,1) string            % Format option (one of the values above).
        sv_bus   (:,1) string            % Bus tags in the row order of rm_pf.
        rm_pf    (:,4) double            % [pu] Solution as in powerflow_matrix: columns V, I, P, Q.
        f_result function_handle         % Builds the result object for "GUILDAorigin".
    end
    arguments (Output)
        out                              % The first output in the requested form.
    end
    switch s_format
        case "V"
            out = rm_pf(:,1);
        case "powerflow(mat)"
            out = rm_pf;
        case "powerflow(tab)"
            out = powerflow_table(sv_bus, rm_pf);
        case "GUILDAorigin"
            out = f_result();
    end
end
