function [result,flag,output] = solve(obj, net, s_options)
% <@Desc>
% Builds the optimal power flow problem of net (net.build_opf_problem) for
% s_options.Method, solves it with the effective settings s_options and returns the
% solution as an OPFResult. The solver is only read: nothing is written back into it.
% Called by net.optimize_powerflow; calling it directly is for advanced use.
% <@Role> Analysis
% <@Summary> Build and solve the optimal power flow with the given settings.
% <@Signatures>
% [
%   "[result, flag, output] = solve(obj, net)",
%   "[result, flag, output] = solve(obj, net, s_options)"
% ]
% <@Parameters>
% [
%   {"Name": "obj", "Type": "OptimalPowerFlow", "Description": "Solver (net.solver_OPF).", "Required": true, "Default": "-"},
%   {"Name": "net", "Type": "PowerNetwork", "Description": "Network to optimize.", "Required": true, "Default": "-"},
%   {"Name": "s_options", "Type": "struct", "Description": "Effective settings (output of get_options).", "Required": false, "Default": "obj.get_options()"}
% ]
% <@Returns>
% [
%   {"Name": "result", "Type": "OPFResult", "Description": "Bus, connection and branch values of the solution."},
%   {"Name": "flag", "Type": "optim.problemdef.ExitFlag", "Description": "exitflag of solve (positive = solved)."},
%   {"Name": "output", "Type": "struct", "Description": "Solver details; output.message describes the outcome."}
% ]
    arguments
        obj
        net
        s_options (1,1) struct = obj.get_options()
    end
    t0 = tic;
    str_method = s_options.Method;

    % get OPF problem
    [OPFprob,x0] = net.build_opf_problem("Method",str_method);

    % solve OPF problem
    [~, c_nv] = obj.optimoption(OPFprob, s_options);
    [sol,fval,flag,output,lambda] = solve(OPFprob,x0,c_nv{:});
    if isstruct(fval)
        fval = sum(cell2mat(struct2cell(fval)));
    end

    [tab_bus, tab_cub] = format_bus(net, sol, str_method);
    tab_branch         = format_branch(net, sol, str_method);

    result = OPFResult(net, obj, s_options, flag, output, t0, ...
                       tab_bus, tab_cub, tab_branch, fval, lambda, OPFprob);
end


function [tab_bus, tab_cub] = format_bus(net, sol, str_method)
% tab_cub has one row per connection to a bus, in bus order:
%   the bus's components ("<component>"), then the branch ends at the bus ("<branch>_<bus>").
% Each row is the injection into the bus (Iphasor, P, Q from the component / branch into the bus).
    a_Bus    = net.a_Bus;
    a_Branch = net.a_Branch;
    rm_bus   = [];
    rm_cub   = [];
    str_cub  = [];

    cv_strBranchBus = cellfun(@(br) string(br.a_Bus), a_Branch, "UniformOutput", false);

    for i_bus = 1:numel(a_Bus)
        bus     = a_Bus{i_bus};
        str_bus = string(bus);
        a_com   = bus.a_Component;
        if isempty(a_com); a_com = cell(0,1); end
        str_bra = string.empty(0,1);
        for i_bra = 1:numel(a_Branch)
            if any(cv_strBranchBus{i_bra} == str_bus)
                str_bra = [str_bra; string(a_Branch{i_bra})+"_"+str_bus];  %#ok
            end
        end
        str_cub = [str_cub; string(a_com); str_bra];                       %#ok

        switch str_method
            case "AC OPF"
                sol_V = sol.(str_bus);
                c_V   = sol_V(2) * exp(1j*sol_V(1));
                r_P   = 0;
                r_Q   = 0;
                c_I   = 0;
                for i_com = 1:numel(a_com)
                    sol_com = sol.(string(a_com{i_com}));
                    Pcub = sol_com(1);
                    Qcub = sol_com(2);
                    Icub = (Pcub-1j*Qcub)/conj(c_V);
                    r_P  = r_P + Pcub;
                    r_Q  = r_Q + Qcub;
                    c_I  = c_I + Icub;
                    rm_cub = [rm_cub; [Icub,Pcub,Qcub]];                    %#ok
                end
                for i_bra = 1:numel(str_bra)
                    sol_bra = sol.(str_bra(i_bra));
                    rm_cub  = [rm_cub; [sol_bra(3)+1j*sol_bra(4),sol_bra(1),sol_bra(2)]]; %#ok
                end
                rm_bus = [rm_bus; [sol_V(1),sol_V(2),r_P,r_Q,c_V,c_I]];    %#ok

            case "DC OPF"
                rv_P   = cellfun(@(c) sol.(string(c)), a_com);
                rv_Pbr = arrayfun(@(s) sol.(s), str_bra);
                rm_cub = [rm_cub; rv_P(:); rv_Pbr(:)];                      %#ok
                rm_bus = [rm_bus; [sol.(str_bus), 1, sum(rv_P)]];           %#ok

            case "ELD"
                % Branches are ignored in ELD, so the branch rows are NaN.
                rv_P   = cellfun(@(c) sol.(string(c)), a_com);
                rm_cub = [rm_cub; rv_P(:); nan(numel(str_bra),1)];          %#ok
                rm_bus = [rm_bus; sum(rv_P)];                               %#ok
        end
    end

    switch str_method
        case "AC OPF"
            tab_bus = array2table( rm_bus, "VariableNames",["Varg","V","P","Q","Vphasor","Iphasor"], "RowNames",string(a_Bus));
            tab_cub = array2table( rm_cub, "VariableNames",["Iphasor","P","Q"], "RowNames",str_cub);
        case "DC OPF"
            tab_bus = array2table( rm_bus, "VariableNames",["Varg","V","P"], "RowNames",string(a_Bus));
            tab_cub = array2table( rm_cub, "VariableNames","P", "RowNames",str_cub);
        case "ELD"
            tab_bus = array2table( rm_bus, "VariableNames","P", "RowNames",string(a_Bus));
            tab_cub = array2table( rm_cub, "VariableNames","P", "RowNames",str_cub);
    end
end


function tab = format_branch(net, sol, str_method)
% Flows at both ends of each branch (from = br.a_Bus{1}, to = br.a_Bus{2}), as power and
% current flowing into the branch: the negative of the branch-end rows of tab_cub.
% ELD ignores branches, so its values are NaN.
    n_br       = numel(net.a_Branch);
    str_branch = strings(n_br,1);
    cm_S       = nan(n_br,2);
    cm_I       = nan(n_br,2);
    for k = 1:n_br
        br  = net.a_Branch{k};
        str_branch(k) = string(br);
        str_end = string(br) + "_" + string(br.a_Bus);
        for i_end = 1:2
            switch str_method
                case "AC OPF"
                    v = sol.(str_end(i_end));
                    cm_S(k,i_end) = -(v(1) + 1j*v(2));
                    cm_I(k,i_end) = -(v(3) + 1j*v(4));
                case "DC OPF"
                    cm_S(k,i_end) = -sol.(str_end(i_end));
            end
        end
    end
    switch str_method
        case "AC OPF"
            tab = table(real(cm_S(:,1)), imag(cm_S(:,1)), real(cm_S(:,2)), imag(cm_S(:,2)), ...
                        cm_I(:,1), cm_I(:,2), real(sum(cm_S,2)), imag(sum(cm_S,2)), ...
                        'VariableNames', ["Pfrom","Qfrom","Pto","Qto","Ifrom","Ito","Ploss","Qloss"], ...
                        'RowNames', str_branch);
        otherwise
            tab = table(real(cm_S(:,1)), real(cm_S(:,2)), real(sum(cm_S,2)), ...
                        'VariableNames', ["Pfrom","Pto","Ploss"], ...
                        'RowNames', str_branch);
    end
end
