classdef abstract < component

    properties
        porttype = 'rate';
    end

    methods
        function obj = abstract()
            obj.Tag = 'Load';
            obj.set_InputType('Rate');
        end
    end

end
