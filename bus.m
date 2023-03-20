classdef bus < handle
% 母線を定義するスーパークラス
% 'bus_PV'と'bus_PQ','bus_slack'を子クラスに持つ。

    properties
        CostFunction = @(obj,V,I) 0;
    end

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
            obj.edited  = true;
        end

        function set_CostFunction(obj,func)
            obj.CostFunction = func;
        end
        function set.CostFunction(obj,func)
            obj.check_function(func,'double')
            obj.CostFunction = func;
        end

        function check_function(obj, f, val_type)
            try
                val = f(obj, obj.V_equilibrium, obj.I_equilibrium);
                if ~isa(val,val_type); error_code =1; 
                else; error_code = 0; end
            catch
                error_code = 2;
            end
            switch error_code
                case 1; error(['The type of the function output should be ',val_type])
                case 2; error('The function must be in the form of f(obj,Vfrom,Vto)')
            end
        end

    end
end

