function [result,flag,output] = solve(obj, net, s_options)
% <@Desc>
% Runs the power flow calculation of net with the effective settings s_options and
% returns the computed values as a PowerFlowResult. The solver is only read: nothing is
% written back into it. Called by net.calculate_powerflow; calling it directly is for
% advanced use.
% <@Role> Analysis
% <@Summary> Solve the power flow with the given settings.
% <@Signatures>
% [
%   "[result, flag, output] = solve(obj, net)",
%   "[result, flag, output] = solve(obj, net, s_options)"
% ]
% <@Parameters>
% [
%   {"Name": "obj", "Type": "PowerFlowCalculation", "Description": "Solver (net.solver_PF).", "Required": true, "Default": "-"},
%   {"Name": "net", "Type": "PowerNetwork", "Description": "Network with a slack bus.", "Required": true, "Default": "-"},
%   {"Name": "s_options", "Type": "struct", "Description": "Effective settings (output of get_options).", "Required": false, "Default": "obj.get_options()"}
% ]
% <@Returns>
% [
%   {"Name": "result", "Type": "PowerFlowResult", "Description": "Bus and branch values of the solution."},
%   {"Name": "flag", "Type": "double or logical", "Description": "exitflag of fsolve (algebraic) or convergence (dynamic)."},
%   {"Name": "output", "Type": "struct", "Description": "Solver details; output.message describes the outcome."}
% ]
    arguments
        obj
        net
        s_options (1,1) struct = obj.get_options()
    end
    t0 = tic;

    tab_Ymat  = net.get_admittance_matrix;
    tab_PFset = tools.vcellfun(@(b) b.get_pf_set, net.a_Bus);
    str_bus   = string(tab_PFset.Properties.RowNames);
    cm_Y      = tab_Ymat{str_bus,str_bus};

    switch s_options.Method
        case "algebraic"
            [cv_Vbus,flag,output,cm_Vhistory,rv_step] = obj.solve_algebraic(cm_Y, tab_PFset, s_options);
        case "dynamic"
            [cv_Vbus,flag,output,cm_Vhistory,rv_step] = obj.solve_dynamic(cm_Y, tab_PFset, s_options);
    end

    % Vbus -> Ibus -> Pbus,Qbus
    cv_Ibus = cm_Y*cv_Vbus;
    cv_Sbus = cv_Vbus .* conj(cv_Ibus);

    % convert double->table
    tab_bus = array2table(...
        [angle(cv_Vbus),abs(cv_Vbus),real(cv_Sbus),imag(cv_Sbus),cv_Vbus,cv_Ibus], ...
        "VariableNames",["Varg","V","P","Q","Vphasor","Iphasor"],"RowNames",str_bus);
    tab_branch = branch_flow(net, str_bus, cv_Vbus);

    result = PowerFlowResult(net, obj, s_options, flag, output, t0, ...
                             tab_bus, tab_branch, cm_Vhistory, rv_step);

    % Notify
    if flag<=0
        switch s_options.WhenFailed
        case "WARN" ; warning(output.message)
        case "ERROR"; error(output.message)
        case "DISP" ; disp(output.message)
        end
    end
end


function tab = branch_flow(net, str_bus, cv_Vbus)
% Power and current at both ends of each branch (from = br.a_Bus{1}, to = br.a_Bus{2})
    n_br  = numel(net.a_Branch);
    cm_I  = zeros(n_br,2);
    cm_S  = zeros(n_br,2);
    for k = 1:n_br
        br = net.a_Branch{k};
        [~, idx] = ismember(string(br.a_Bus), str_bus);
        cv_Vb = cv_Vbus(idx(:));
        cv_Ib = br.get_admittance_matrix() * cv_Vb;
        cm_I(k,:) = cv_Ib.';
        cm_S(k,:) = (cv_Vb .* conj(cv_Ib)).';
    end
    str_branch = strings(n_br,1);
    for k = 1:n_br
        str_branch(k) = string(net.a_Branch{k});
    end
    tab = table(real(cm_S(:,1)), imag(cm_S(:,1)), real(cm_S(:,2)), imag(cm_S(:,2)), ...
                cm_I(:,1), cm_I(:,2), real(sum(cm_S,2)), imag(sum(cm_S,2)), ...
                'VariableNames', ["Pfrom","Qfrom","Pto","Qto","Ifrom","Ito","Ploss","Qloss"], ...
                'RowNames', str_branch);
end
