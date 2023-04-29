classdef HasGridCode < base_class.handleCopyable

    properties(SetAccess = protected)
        is_connected
    end

    properties
        grid_code
        restoration
    end

    methods(Abstract)
        value = usage_grid_code(func);
        value = usage_restoration(func);
    end

    methods

        %機器の接続状況を示すis_connectedプロパティを操作するメソッド
        function connect(obj)
            obj.is_connected = true;
        end
        function disconnect(obj)
            obj.is_connected = false;
        end

        % グリッドに接続/解列する条件式を定義する際のチェックメソッド
        function set.grid_code(obj,value)
            check_grid_code(value);
            obj.grid_code = value;
        end
        function set.restoration(obj,value)
            check_restoration(value);
            obj.restoration = value;
        end
    end

    methods(Access=private)
        function check_grid_code(obj,func)
            val = obj.usage_grid_code(func);
            if ~islogical(val) && ~isnan(val)
                error('The output value of the function must be logical')
            end   
        end

        function check_restoration(obj,func)
            val = obj.usage_restoration(func);
            if ~islogical(val) && ~isnan(val)
                error('The output value of the function must be logical')
            end  
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