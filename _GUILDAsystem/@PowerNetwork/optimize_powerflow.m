function [powerflow_bus, powerflow_cub, flag, output, lambda, OPFprob] = optimize_powerflow(obj,options)
    arguments
        obj 
        options.methods (1,1) string {mustBeMember(options.methods,["ELD","DC OPF","AC OPF"])} = "AC OPF";
    end

    % get OPF problem
    [OPFprob,x0] = obj.build_opf_problem("methods",options.methods);

    % solve OPF problem
    [sol,~,flag,output,lambda] = solve(OPFprob,x0);
    
    a_Bus    = obj.a_Bus;
    a_Branch = obj.a_Branch;
    rm_bus   = [];
    rm_cub   = [];
    str_cub  = [];

    % powerflow_cub has one row per connection to a bus, in bus order:
    %   the bus's components ("<component>"), then the branch ends at the bus ("<branch>_<bus>").
    % Each row is the injection into the bus (Iphasor, P, Q from the component / branch into the bus).
    cv_strBranchBus = cellfun(@(br) string(br.a_Bus), a_Branch, "UniformOutput", false);
        
    % Format sol
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

        switch options.methods
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

    switch options.methods
        case "AC OPF"
            powerflow_bus = array2table( rm_bus, "VariableNames",["Varg","V","P","Q","Vphasor","Iphasor"], "RowNames",string(a_Bus));
            powerflow_cub = array2table( rm_cub, "VariableNames",["Iphasor","P","Q"], "RowNames",str_cub);
        case "DC OPF"
            powerflow_bus = array2table( rm_bus, "VariableNames",["Varg","V","P"], "RowNames",string(a_Bus));
            powerflow_cub = array2table( rm_cub, "VariableNames","P", "RowNames",str_cub);
        case "ELD"
            powerflow_bus = array2table( rm_bus, "VariableNames","P", "RowNames",string(a_Bus));
            powerflow_cub = array2table( rm_cub, "VariableNames","P", "RowNames",str_cub);
    end

end
