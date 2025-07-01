classdef test < handle
    properties
        val
    end

    methods
        function obj = test(mat)
            arguments
                mat (1,1) double {mustBeNonnegative,mustBeInteger}
            end
            mat
        end

        function val = isValid(obj)
            val = true;
        end
    end
end