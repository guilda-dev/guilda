classdef bus   < base_class.Edit_Monitoring & base_class.HasCostFunction
% 母線を定義するスーパークラス
% 'bus_PV'と'bus_PQ','bus_slack'を子クラスに持つ。

    properties(SetAccess = protected)
        index
        V_equilibrium %潮流状態の母線電圧フェーザ
        I_equilibrium %潮流状態の母線電流フェーザ
        shunt %シャント値
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
            obj.set_component(component.empty());
            obj.set_shunt(shunt(:));
            obj.Tag = 'Bus';
        end

        function setprop(obj,name,val)
            obj.(name)=val;
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
        
        function set_shunt(obj, shunt)
            if numel(shunt) == 2
                shunt = shunt(1) + 1j*shunt(2);
            end
            obj.shunt = shunt(:);
            obj.editted;
        end
        
        function set_component(obj, component)
            if isa(component, 'component')
                component.register_parent(obj,'overwrite')
                obj.register_child(component,'overwrite')
                if ~isempty(obj.V_equilibrium) && ~isempty(obj.I_equilibrium)
                    component.set_equilibrium;
                end
            else
                error('must be a child of component');
            end
        end

        function c = get.component(obj)
            c = obj.children{1};
        end

        function p = get.power_network(obj)
            p = obj.parents{1};
        end
        
        function val = usage_function(obj,func)
            V = tools.complex2vec(obj.V_equilibrium);
            I = tools.complex2vec(obj.I_equilibrium);
            try
                val = func(obj,0,V,I);
            catch
                error(['The function handle seems to be in the wrong format.',newline,...
                       'It must be in the following format',newline,...
                       'func = @(obj,t,V,I) ~',newline,...
                       '・obj : own class object',newline,...
                       '・t = time(scalar)',newline,...
                       '・V = [real(V);imag(V)]',newline,...
                       '・I = [real(I);imag(I)]',newline])
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

