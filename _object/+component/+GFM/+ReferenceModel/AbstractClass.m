classdef AbstractClass < handle
    properties
        parameter
        converter
    end

    properties(Dependent)
        omega0
    end

    methods(Abstract)
        nx = get_nx(obj)
        nu = get_nu(obj)
        
        [dx,con] = get_dx_constraint(obj, t, x, V, I, u)
        [x_ref, u_ref, vdq_st, idq_st] = get_equilibrium(obj,V,I)
        [delta,omega] = get_Vterminal(obj,x,V,I,u)
    end

    methods
        function omega0 = get.omega0(obj)
            omega0 = obj.converter.omega0;
        end

        function tag = naming_state(obj)
            nx = obj.get_nx;
            tag = tools.arrayfun(@(i) ['x',num2str(i),'_ref'],1:nx);
        end

        function tag = naming_port(obj)
            nu = obj.get_nu;
            tag = tools.arrayfun(@(i) ['u',num2str(i),'_ref'],1:nu);
        end
    end
end