classdef abstract < component

    properties
        porttype = 'rate';
    end

    methods
        function obj = abstract()
            obj.Tag = 'Load';
        end

        function set.porttype(obj,val)
            switch val
                case {'rate' ,'Rate' }
                    obj.porttype = 'rate';
                case {'value','Value','Val','val'}
                    obj.porttype = 'value';
                otherwise
                    error('porttype must be either "rate" or "value".')
            end
            obj.porttype = val;
            obj.set_equilibrium;
            obj.set_linear_matrix;
        end
    end

end
