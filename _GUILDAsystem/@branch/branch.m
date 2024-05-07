classdef branch < handle & base_class.HasGridCode & base_class.HasCostFunction
% 送電網を定義するスーパークラス
% 'branch_pi'と'branch_pi_transfer'を子クラスに持つ。
    
    properties(Dependent,Access=public)
        network
        from
        to
    end

    properties(SetAccess=protected)
        bus_from
        bus_to
    end

    methods(Abstract)
        y = get_admittance_matrix(obj);
    end
    
    methods
        function obj = branch(from, to)
            obj.to = to;
            obj.from = from;
            obj.Tag = 'Line';
        end


        %% CostFunctionに代入する関数ハンドルのチェックメソッド
        val = check_CostFunction(obj,func)


        %% Setメソッド
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            function set.from(obj,val)
                if isa(obj.network,'power_network')
                    obj.bus_from = obj.network.a_bus{val};
                else
                    obj.bus_from = struct('index',val);
                end
            end
            function set.to(obj,val)
                if isa(obj.network,'power_network')
                    obj.bus_to = obj.network.a_bus{val};
                else
                    obj.bus_to = struct('index',val);
                end
            end


        %% Getメソッド
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            function n = get.network(obj)
                if ~isempty(obj.parents)
                    n = obj.parents{1};
                else
                    n = [];
                end
            end
            function n = get.from(obj)
                n = obj.bus_from.index;
            end
            function n = get.to(obj)
                n = obj.bus_to.index;
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

