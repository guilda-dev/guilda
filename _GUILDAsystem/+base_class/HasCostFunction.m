classdef HasCostFunction < base_class.handleCopyable
    properties
        CostFunction
    end

    methods(Abstract)
        value = check_CostFunction(func);
    end
    
    methods

        % エネルギー関数を定義する際のチェックメソッド
        function set.CostFunction(obj,func)
            if obj.check %#ok
                obj.check_CostFunction(func);
            end
            obj.CostFunction = func;
        end

        % クラス内にget_CostFunctionメソッドが存在する場合、その関数をCostFunctionとして設定する
        function set_CostFunctionMethod(obj)
            if ismethod(obj,'get_CostFunction')
                obj.CostFunction = @(obj,varargin) obj.get_CostFunction(varargin{:});
            end
        end

        % エネルギー関数の時系列データを計算するメソッド
        function out = get_cost_vectorized(obj, varargin)
            if isempty(obj.CostFunction)
                out = zeros(size(varargin{1},1),0);
                return
            end
            
            nvar = numel(varargin);
            func = cell(1,nvar);
            for i = 1:nvar
                if iscell(varargin{i})
                    func{i} = @(tidx) tools.cellfun(@(c) c(tidx,:).', varargin{i});
                else
                    func{i} = @(tidx) varargin{i}(tidx,:).';
                end
            end
            fvar = @(i) tools.cellfun(@(f) f(i), func);
            
            var = fvar(1);
            cost = obj.CostFunction(obj,var{:});
            
            out = zeros(numel(t), numel(cost));
            out(1, :) = cost(:)';
            
            for i = 2:numel(t)
                var = fvar(i);
                cost = obj.CostFunction(obj,var{:});
                out(i, :) = cost(:)';
            end
        end
    end

    properties(Access=private)
        check = false;
    end

    methods(Access = protected)
        function sudo_set_CostFunction(obj)
            if ismethod(obj,'get_CostFunction')
                obj.check = false;
                obj.CostFunction = @(obj,varargin) obj.get_CostFunction(varargin{:});
                obj.check = true;
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