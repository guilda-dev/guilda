classdef branch < handle
% 送電網を定義するスーパークラス
% 'branch_pi'と'branch_pi_transfer'を子クラスに持つ。

    properties
        CostFunction = @(obj,Vfrom,Vto) 0;
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
        end

        function check_function(obj, f, val_type)
            try
                val = f(obj,[1;1],[1.1;1.1]);
                if ~isa(val,val_type); error_code =1; 
                else; error_code = 0; end
            catch
                error_code = 2;
            end
            switch error_code
                case 1; error(['The return type of the function should be ',val_type])
                case 2; error('The function must be in the form of f(obj,Vfrom,Vto)')
            end
        end

         % エネルギー関数を定義する際のチェックメソッド
        function set_CostFunction(obj,func)
            obj.CostFunction = func;
        end

        function set.CostFunction(obj,func)
            obj.check_function(func,'double')
            obj.CostFunction = func;
        end

    end
end

