classdef abstract < component

    properties
        porttype = 'rate';
    end

    methods
        function obj = abstract()
            obj.Tag = 'Load';
            obj.InputType = 'Rate';
        end
    end

end
