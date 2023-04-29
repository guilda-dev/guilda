classdef HasCostFunction < base_class.handleCopyable
    properties
        CostFunction
    end

    methods(Abstract)
        value = usage_CostFunction(func);
    end
    
    methods

        % エネルギー関数を定義する際のチェックメソッド
        function set.CostFunction(obj,value)
            check_CostFunction(value);
            obj.grid_code = value;
        end
    end

    methods(Access=private)
        function check_CostFunction(obj,func)
            obj.usage_CostFunction(func);
        end
    end

    methods(Access=protected)
        function PropEditor_Set(obj,prop,val)
            obj.(prop) = val;
        end
        function val = PropEditor_Get(obj,prop)
            val = obj.(prop);
        end
    end
end