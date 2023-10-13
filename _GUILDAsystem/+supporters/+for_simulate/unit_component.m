classdef unit_component < supporters.for_simulate.unit

    properties(Dependent)
        get_dx_con_func
        x_init
    end

    methods
        function obj = unit_component(object,solver,idx,linear)
            obj@supporters.for_simulate.unit(object,solver,idx,linear)
        end

        function set_linear(obj,linear)
            obj.linear = linear;
            
            c = obj.object;
            if obj.linear
                c.get_dx_con_func = @c.get_dx_constraint_linear;
            else
                c.get_dx_con_func = @c.get_dx_constraint;
            end
        end

        function out = get.x_init(obj)
            if any(isnan(obj.xlast))
                warning('off')
                c = obj.object.component.copy;
                x0(obj.logimat.x(:,i)) = c.set_equilibrium(V0comp(i),I0comp(i));
                warning('on')
            end
        end
    end
end