classdef branch < handle
% 送電網を定義するスーパークラス
% 'branch_pi'と'branch_pi_transfer'を子クラスに持つ。

    properties
        CostFunction = @(obj,Vfrom,Vto) 0;
        grid_code = @(obj,Vfrom,Vto) nan;
    end
    
    properties(SetAccess = private)
        from
        to
    end

    properties(SetAccess = protected)
        is_connected = true;
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

        % グリッドに接続/解列する条件式を定義する際のチェックメソッド
        function set_grid_code(obj, code)
            obj.grid_code = code;
        end
        function set.grid_code(obj, code)
            obj.check_function(code,'logical');
            obj.grid_code = code;
        end

        function connect(obj)
            obj.is_connected = true;
        end
        function disconnect(obj)
            obj.is_connected = false;
        end

    end
end

