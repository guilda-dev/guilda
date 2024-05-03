classdef HasGridCode < base_class.handleCopyable & base_class.Edit_Monitoring

    properties(SetAccess = protected)
        parallel = 'on';
    end

    properties
        grid_code
    end

    methods(Abstract)
        value = usage_function(func);
    end

    methods

        %機器の接続状況を示すis_connectedプロパティを操作するメソッド
        function connect(obj)
            obj.parallel = 'on';
            obj.editted;
        end
        function disconnect(obj)
            obj.parallel = 'off';
            obj.editted;
        end

        % グリッドに接続/解列する条件式を定義する際のチェックメソッド
        function set.grid_code(obj,value)
            obj.check_grid_code(value);
            obj.grid_code = value;
        end

    end

    methods(Access=private)
        function check_grid_code(obj,func)
            val = obj.usage_function(func);
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