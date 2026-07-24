classdef odeSimulationResult < auxiliary

    properties 

    end
    properties (SetAccess=private)
        odeNetwork    
        odeResults
    end

    methods
        function obj = odeSimulationResult(net, sol)
            
            % obj.odeNetwork = net.info(false);
            a_bus = net.a_Bus;                        

            sol = reshape(sol, [], 1);
            t = cell2mat( cellfun(@(T) T.t, sol, 'UniformOutput', false) );
            X = cell2mat( cellfun(@(T) T.x, sol, 'UniformOutput', false) );
            I = cell2mat( cellfun(@(T) T.i, sol, 'UniformOutput', false) );            

            obj.odeResults.t = t{:,1};
            for i=1:numel(a_bus)

                a_Comp = a_bus{i}.a_Component;   

                obj.odeResults.Bus(i).Component = struct();
                for j=1:numel(a_Comp)
                    c_idx = a_Comp{j}.iv_odeX;
                    sol_c_idx = X(:,c_idx);
                    sol_c_idx.Properties.VariableNames = a_Comp{j}.sv_x;
                    obj.odeResults.Bus(i).Component(j).X = sol_c_idx;                    

                    c_idx = a_Comp{j}.iv_odeU;
                    sol_c_idx = X(:,c_idx);
                    sol_c_idx.Properties.VariableNames = a_Comp{j}.sv_u;
                    obj.odeResults.Bus(i).Component(j).U = sol_c_idx;                    
                end
                
                b_idx = a_bus{i}.iv_odeX;

                sol_V_idx = X{:,b_idx};                
                sol_I_idx = I{:,[2*i-1,2*i]};
                sol_P_idx = array2table( sol_V_idx(:,1) .* sol_I_idx(:,1) + sol_V_idx(:,2) .* sol_I_idx(:,2) );                
                sol_Q_idx = array2table( sol_V_idx(:,2) .* sol_I_idx(:,1) - sol_V_idx(:,1) .* sol_I_idx(:,2) );

                sol_V_idx = X(:,b_idx);
                sol_I_idx = I(:,[2*i-1,2*i]);

                sol_V_idx.Properties.VariableNames = ["Vreal","Vimag"];
                sol_I_idx.Properties.VariableNames = ["Ireal","Iimag"];
                sol_P_idx.Properties.VariableNames = "P";
                sol_Q_idx.Properties.VariableNames = "Q";
                
                obj.odeResults.Bus(i).V  = sol_V_idx;
                obj.odeResults.Bus(i).I  = sol_I_idx;
                obj.odeResults.Bus(i).PQ = [sol_P_idx,sol_Q_idx]; 
            end                
        end
    end   

end