classdef HasGridCode < base_class.handleCopyable & base_class.Edit_Monitoring

    properties(SetAccess = protected)
        parallel = 'on';
    end

    properties
        grid_code = struct('parallel_on',[],'parallel_off',[])
    end

    methods(Abstract)
        value = check_CostFunction(func);
    end

    methods

        %機器の接続状況を示すis_connectedプロパティを操作するメソッド
        function connect(obj)
            if strcmp(obj.parallel,'off')
                obj.parallel = 'on';
                obj.editted("parallel on");
            end
        end
        function disconnect(obj)
            if strcmp(obj.parallel,'on')
                obj.parallel = 'off';
                obj.editted("parallel off");
            end
        end

        % グリッドに接続/解列する条件式を定義する際のチェックメソッド
        function set_grid_code(obj,value, onoff)
            arguments
                obj
                value
                onoff = false;
            end
            obj.check_grid_code(value);
            switch onoff
                case {'on','ON',true}
                    obj.grid_code.parallel_on  = value;
                case {'off','OFF',false}
                    obj.grid_code.parallel_off = value;
            end
        end
        % function set.grid_code(obj,value)
        %     obj.check_grid_code(value);
        %     obj.grid_code.parallel_off = value;
        % end
    end

    methods(Access=private)
        function check_grid_code(obj,func)
            val = obj.check_CostFunction(func);
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