classdef branch < base_class.HasCostFunction & base_class.HasGridCode
% 送電網を定義するスーパークラス
% 'branch_pi'と'branch_pi_transfer'を子クラスに持つ。
    
    properties(Dependent)
        network
    end

    properties(SetAccess = private)
        from
        to
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

        function n = get.network(obj)
            n = obj.parents{1};
        end
    end

    methods(Access=protected)
        function PropEditor_Set(obj,prop,val)
            obj.(prop) = val;
        end
        function val = PropEditor_Get(obj,prop)
            val = obj.(prop);
        end

        function something_has_changed(obj)
            if isa(obj.net,'power_network')
                obj.net.something_has_changed;
            end
        end
    end
end

