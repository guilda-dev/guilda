classdef bus < handle
% 母線を定義するスーパークラス
% 'bus_PV'と'bus_PQ','bus_slack'を子クラスに持つ。
    
    properties(SetAccess = private)
        component %機器を格納するプロパティ
        V_equilibrium %潮流状態の母線電圧フェーザ
        I_equilibrium %潮流状態の母線電流フェーザ
        shunt %シャント値
        
        edited = false; %編集済みかどうか
    end
    
    methods(Abstract)
        out = get_constraint(obj, Vr, Vi, P, Q)
    end
    
    methods
        function obj = bus(shunt)
            obj.set_component(component_empty());
            obj.set_shunt(shunt(:));
        end
        
        function nx = get_nx(obj)
            nx = numel(obj.component.x_equilibrium);
        end
        
        function nu = get_nu(obj)
            nu = obj.component.get_nu();
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
            obj.component.set_equilibrium(Veq, Ieq);
            obj.edited = false;
        end
        
        function set_shunt(obj, shunt)
            if numel(shunt) == 2
                shunt = shunt(1) + 1j*shunt(2);
            end
            obj.shunt = shunt(:);
        end
        
        function set_component(obj, component)
            if isa(component, 'component')
                obj.component = component;
                if ~isempty(obj.V_equilibrium)
                    obj.component.set_equilibrium(obj.V_equilibrium, obj.I_equilibrium);
                end
            else
                error('must be a child of component');
            end
        end

        function edit_parameter(obj)
            pbj.edited  = true;
        end
    end
end

