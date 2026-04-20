function [powerflow_bus, powerflow_cub, flag, output, lambda, OPFprob] = optimize_powerflow(obj,options)
    arguments
        obj 
        options.methods (1,1) string {mustBeMember(options.methods,["ELD","DC OPF","AC OPF"])} = "AC OPF";
    end

    % get OPF problem
    [OPFprob,x0] = obj.build_opf_problem("methods",options.methods);

    % solve OPF problem
    [sol,~,flag,output,lambda] = solve(OPFprob,x0);
    
    a_Bus = obj.a_Bus;
    rm_bus  = [];
    rm_cub  = [];
    str_cub = [];
        
    % Format sol
    switch options.methods
        case "AC OPF"
        
            for i_bus = 1:numel(a_Bus)
                c_I = 0;
                r_P = 0;
                r_Q = 0;
                bus = a_Bus{i_bus};
                
                a_cub = bus.a_Cubicle;
                sol_V = sol.(string(bus));
                c_V   = sol_V(2) * exp(1j*sol_V(1));
        
                for i_cub = 1:numel(a_cub)
                    cub = a_cub{i_cub};
                    str_cub = [str_cub; string(cub)];                       %#ok
                    switch cub.str_ConnectType
                        case "Component"
                            sol_mac = sol.(string(cub.a_Connect));
                            Pcub = sol_mac(1);
                            Qcub = sol_mac(2);
                            Icub = (Pcub-1j*Qcub)/conj(c_V);
                            r_P  = r_P + Pcub;
                            r_Q  = r_Q + Qcub;
                            c_I  = c_I + Icub;
                        case "Branch"
                            sol_cub = sol.(string(cub));
                            Pcub = sol_cub(1);
                            Qcub = sol_cub(2); 
                            Icub = sol_cub(3) + 1j*sol_cub(4);
                    end
                    rm_cub = [rm_cub; [Icub,Pcub,Qcub]];                    %#ok
                end
                rm_bus    = [rm_bus; [sol_V(1),sol_V(2),r_P,r_Q,c_V,c_I]];  %#ok
            end
            powerflow_bus = array2table( rm_bus, "VariableNames",["Varg","V","P","Q","Vphasor","Iphasor"], "RowNames",string(a_Bus));
            powerflow_cub = array2table( rm_cub, "VariableNames",["Iphasor","P","Q"], "RowNames",str_cub); 


        case "DC OPF"
            for i_bus = 1:numel(a_Bus)
                r_P = 0;
                bus = a_Bus{i_bus};
                
                a_cub = bus.a_Cubicle;
        
                for i_cub = 1:numel(a_cub)
                    cub     = a_cub{i_cub};
                    Pcub    = nan;
                    str_cub = [str_cub; string(cub)];                       %#ok
                    if cub.str_ConnectType=="Component"
                        Pcub = sol.(string(cub.a_Connect));
                        r_P  = r_P + Pcub;
                    end
                    rm_cub = [rm_cub; Pcub];                                %#ok
                end
                rm_bus    = [rm_bus; [ sol.(string(bus)), 1, r_P]];          %#ok
            end
            powerflow_bus = array2table( rm_bus, "VariableNames",["Varg","V","P"], "RowNames",string(a_Bus));
            powerflow_cub = array2table( rm_cub, "VariableNames","P", "RowNames",str_cub); 
            

        case "ELD"
            for i_bus = 1:numel(a_Bus)
                r_P = 0;
                bus = a_Bus{i_bus};
                a_cub = bus.a_Cubicle;
                for i_cub = 1:numel(a_cub)
                    cub     = a_cub{i_cub};
                    Pcub    = nan;
                    str_cub = [str_cub; string(cub)];                       %#ok
                    if cub.str_ConnectType=="Component"
                        Pcub = sol.(string(cub.a_Connect));
                        r_P  = r_P + Pcub;
                    end
                    rm_cub = [rm_cub; Pcub];                                %#ok
                end
                rm_bus    = [rm_bus; r_P];                                  %#ok
            end
            powerflow_bus = array2table( rm_bus, "VariableNames","P", "RowNames",string(a_Bus));
            powerflow_cub = array2table( rm_cub, "VariableNames","P", "RowNames",str_cub); 
            
    end

end