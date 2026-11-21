function check_step_data(obj, s_method, sv_field)
% Stop with GUILDA:ResultCPF:NoStepData when the result lacks the data of the steps.
%
% The plots of the steps read the data that net.calculate_continuation_powerflow stores
% for every step (tab_variable, rm_variable, cm_Icomponent, sct_network, rv_sigmaMin). A
% ResultCPF built by hand, or by a solver that does not give them, has empty fields.
    arguments (Input)
        obj      ResultCPF        % The result.
        s_method (1,1) string     % Method that needs the data (for the message).
        sv_field (1,:) string     % Fields read by the method.
    end
    arguments (Output)
    end
    n_step = numel(obj.rv_lambda);
    for s_field = sv_field
        val = obj.(s_field);
        switch s_field
            case "sct_network"
                l_ok = isfield(val, "a_Bus") && isfield(val, "a_Branch") && numel(val.a_Bus) == numel(obj.sv_bus);
            case "rm_variable"
                l_ok = size(val, 1) == n_step && size(val, 2) == height(obj.tab_variable);
            case {"cm_Icomponent", "cm_Vbus", "rv_sigmaMin"}
                l_ok = size(val, 2) == n_step && ~isempty(val);
            otherwise
                l_ok = ~isempty(val);
        end
        if n_step == 0 || ~l_ok
            error(msg("GUILDA:ResultCPF:NoStepData", s_method, s_field));
        end
    end
end
