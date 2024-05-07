classdef bus < handle & base_class.Edit_Monitoring & base_class.HasCostFunction
% 母線を定義するスーパークラス
% 'bus_PV'と'bus_PQ','bus_slack'を子クラスに持つ。

    properties(SetAccess = protected)
        V_equilibrium =1; %潮流状態の母線電圧フェーザ
        I_equilibrium =0; %潮流状態の母線電流フェーザ
    end

    properties
        shunt % シャント値
    end

    properties(Dependent)
        component %機器を格納するプロパティ
        power_network
    end

    properties
        GraphCoordinate = [];
    end

    methods(Abstract)
        out = get_constraint(obj, Vr, Vi, P, Q)
    end
    
    methods

        function obj = bus(shunt)            
            % デフォルトのnetクラスを装着
            net = power_network; 
            net.add_bus(obj);

            obj.shunt = shunt(:);
            obj.Tag = 'Bus';
        end
        
        function set_equilibrium(obj, Veq, Ieq)
            if numel(Veq) == 2
                Veq = Veq(1) + 1j*Veq(2);
            end
            if numel(Ieq) == 2
                Ieq = Ieq(1) + 1j*Ieq(2);
            end
            obj.V_equilibrium = Veq;
            obj.I_equilibrium = Ieq;
            obj.component.set_equilibrium();
        end
        
        function set_component(obj, component)
            if isa(component, 'component')
                component.register_parent(obj,'overwrite')
                component.register_index(obj.index)
                obj.register_child(component,'overwrite')
                obj.editted("component")
            else
                error('variable must be a "component" class!!');
            end
        end


        %% Set method 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function set.shunt(obj, shunt)
            if numel(shunt) == 2
                shunt = shunt(1) + 1j*shunt(2);
            end
            obj.shunt = shunt(:);
            obj.editted("shunt");
        end


        %% Get method
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function c = get.component(obj)
            c = obj.children{1};
        end
        function p = get.power_network(obj)
            p = obj.parents{1};
        end


        %% CostFunctionに代入する関数ハンドルのチェックメソッド
        val = check_CostFunction(obj,func)

       
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

