classdef branch < handle
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

