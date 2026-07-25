classdef abstract < Component
    methods
        function obj = abstract(tag, varargin)
            obj@Component("L"+tag, varargin{:})
            Hz = obj.para_base.Hz;
            obj.set_odefcn(Hz)                        
        end
    end
end