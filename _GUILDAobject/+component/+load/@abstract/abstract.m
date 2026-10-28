classdef abstract < Component
    methods
        function obj = abstract(tag, varargin)
            obj@Component("L"+tag, varargin{:})
            obj.set_odefcn(obj.r_Hz)    % network Hz once attached (set_bus rebuilds)
        end
    end
end