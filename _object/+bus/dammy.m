classdef dammy < bus
% ダミークラス
% componentクラスのconnected_busプロパティのデフォルト値に使用される。

    properties
        Vconst = 1+1j*0;
    end
    
    methods
        function obj = dammy()
            obj@bus(0);
        end
        function out = get_constraint(obj, Vr, Vi, ~, ~)
            out = [Vr-real(obj.Vconst); Vi-obj.imag(obj.Vconst)]; 
        end
        
        function set_component(obj, component)
            if isa(component, 'component')
                component.register_parent(obj,'overwrite')
                obj.register_child(component,'overwrite')
            else
                error('variable must be a "component" class!!');
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