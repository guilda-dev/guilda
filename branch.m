classdef branch < handle
% 送電網を定義するスーパークラス
% 'branch_pi'と'branch_pi_transfer'を子クラスに持つ。

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
    end
end

