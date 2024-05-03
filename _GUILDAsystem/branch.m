classdef branch < base_class.HasGridCode & base_class.HasCostFunction
% 送電網を定義するスーパークラス
% 'branch_pi'と'branch_pi_transfer'を子クラスに持つ。
    
    properties(Dependent,Access=public)
        network
        from
        to
    end

    properties(SetAccess = protected)
        index
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

        function val = usage_function(obj,func)
            try
                val = func(obj,0,[1;0],[1.01,0.01]);
            catch
                error(['The function handle seems to be in the wrong format.',newline,...
                       'It must be in the following format',newline,...
                       'func = @(obj,t,Vfrom,Vto) ~',newline,...
                       '・obj : own class object',newline,...
                       '・t = time(scalar)',newline,...
                       '・Vfrom = [real(V);imag(V)] Bus voltage specified by obj.from',newline,...
                       '・Vto   = [real(V);imag(V)] Bus voltage specified by obj.to',newline])
            end
        end

        %% DependentプロパティのSetGetメソッド
            function n = get.network(obj)
                n = obj.parents{1};
            end
    
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
    
            function n = get.from(obj)
                n = obj.bus_from.index;
            end
    
            function n = get.to(obj)
                n = obj.bus_to.index;
            end

            function setprop(obj,name,val)
                obj.(name)=val;
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

