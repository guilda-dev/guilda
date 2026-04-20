classdef abstract < Component
    methods
        function obj = abstract(tag, varargin)
            obj@Component("L"+tag, varargin{:})
        end
    end
end