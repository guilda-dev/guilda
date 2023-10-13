classdef for_component < handle

    methods
        function check_requirment(obj)
            x = obj.x_equilibrium;
            V = obj.V_equilibrium;
            I = obj.I_equilibrium;
            u = zeros(obj.get_nu, 1);
            if ~isreal(V); V = tools.complex2vec(V);
            elseif isempty(V); V = [1;0]; end
            if ~isreal(I); I = tools.complex2vec(I);
            elseif isempty(I); I = [1;0]; end
            if isempty(x)
                try
                    obj.set_equilibrium(tools.vec2complex(V),tools.vec2complex(I));
                catch
                    error('There are some mistakes in "set_equilibrium" method.')
                end
                x = obj.x_equilibrium;
            end
            
            try
                [dx,con] = obj.get_dx_constraint(0,x,V,I,u);
            catch
                error('There are some mistakes in "get_dx_constraint" method.')
            end
            
            if numel(dx) ~= obj.get_nx
                error('The number of output "dx" from "get_dx_constraint" is not equal to state number.')
            end
            
            if any(abs(dx)>1e-5)
                warning('The output "dx" from "get_dx_constraint" method must be zero matrix at equilibrium.')
            end

            if any(abs(con)>1e-5)
                warning('the output "constraint" from "get_dx_constraint" method should be zero matrix at equilibrium.')
            end

            % 定義しておくことを推奨
            a_method = methods(obj);
            if ~ismember(a_method,'naming_state')
                disp(' ')
                disp('  It is recommended to define the name of the state variable.')
                disp('  If not defined, it will be completed with the names "x1,x2,x3,..."')
                disp('  Define the following function as method in your class')
                disp(' ')
                disp('  -- Definition --')
                disp('  ・Let state variable names be "state1, state2, state3".')
                disp('  ・Variable names must be different.')
                disp('  ・The number of variable names must match the number of states.')
                disp(' ')
                disp('    >> function name = naming_state(obj)')
                disp("    >>    name = {'state1','state2','state3'};")
                disp("    >> end")
                disp(' ')
            end

            if ~ismember(a_method,'naming_port')
                disp(' ')
                disp('  It is recommended to define the name of the input port.')
                disp('  If not defined, it will be completed with the names "u1,u2,..."')
                disp('  Define the following function as method in your class')
                disp(' ')
                disp('  -- Definition --')
                disp('  ・Let input variable names be "port1, port2".')
                disp('  ・Variable names must be different.')
                disp('  ・The number of variable names must match the number of input port.')
                disp(' ')
                disp('    >> function name = naming_port(obj)')
                disp("    >>    name = {'port1','port2'};")
                disp("    >> end")
                disp(' ')
            end

        end
    end

end
