classdef abstract < Component
    methods
        function obj = abstract(tag, varargin)
            obj@Component("L"+tag, varargin{:})
            obj.set_odefcn(60)
        end
    end
end