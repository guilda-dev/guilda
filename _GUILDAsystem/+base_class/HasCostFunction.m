classdef HasCostFunction < base_class.handleCopyable
    properties
        CostFunction
    end

    methods(Abstract)
        value = usage_function(func);
    end
    
    methods

        % エネルギー関数を定義する際のチェックメソッド
        function set.CostFunction(obj,func)
            obj.usage_function(func);
            obj.CostFunction = func;
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

    methods(Access=protected)
        function PropEditor_Set(obj,prop,val)
            obj.(prop) = val;
        end
        function val = PropEditor_Get(obj,prop)
            val = obj.(prop);
        end
    end
end