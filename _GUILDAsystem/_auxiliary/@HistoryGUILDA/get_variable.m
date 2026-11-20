function value = get_variable(obj, s_name)
% Value of a variable of the workspace the code runs in.
%
% <@Examples>
% ```matlab
% h.run("Power flow", "Calculate", "res_pf = net.calculate_powerflow();");
% res_pf = h.get_variable("res_pf");
% ```
    arguments (Input)
        obj                    % The log.
        s_name (1,1) string    % Variable name.
    end
    arguments (Output)
        value  % Value of the variable.
    end
    if ~isfield(obj.sct_variable, s_name)
        error(msg("GUILDA:HistoryGUILDA:UnknownVariable", s_name, ...
            join(string(fieldnames(obj.sct_variable)), ", ")))
    end
    value = obj.sct_variable.(s_name);
end
