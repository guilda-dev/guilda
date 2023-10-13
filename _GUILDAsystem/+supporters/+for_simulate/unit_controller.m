classdef unit_controller < supporters.for_simulate.unit

    methods
        function obj = unit_controller(object,solver,idx,linear)
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
    end
end