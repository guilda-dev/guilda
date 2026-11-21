classdef abstract < Component
% Base class of the grid-following inverter models.
%
% A grid-following inverter connects to one bus, follows the bus voltage and injects the
% current that delivers its power references. Its tag is the bus tag + `"GFL"` + a number,
% e.g. `"B001GFL1"`. In the power flow it is a PQ source: `tab_parameter.powerflow.P` and
% `Q` are injected into the bus (positive for generation). Like a load, its default OPF
% cost is 0 and the OPF keeps its power-flow P and Q when it has no output limits.
% Add a grid-following inverter with `Bus.add_component` and the key `"gfl-static"`.
%
% <@Examples>
% ```matlab
% net = PowerNetwork();
% bus = net.add_bus();
% gfl = bus.add_component("gfl-static", "P", 0.4, "Q", 0.1);
% gfl.tab_parameter.powerflow       % P = 0.4, Q = 0.1
% ```
%
% See also Component, Bus.add_component, component.GFLInverter.Static, component.GFMInverter.abstract

    methods
        function obj = abstract(tag, varargin)
            % Create the inverter and build its model functions.
            %
            % Subclasses call it with `tag`, the tag without the leading `"GFL"`,
            % and `varargin`, the name-value options of `Bus.add_component`.
            % A subclass without a constructor passes on the inputs of
            % `Bus.add_component`, whose `parameter` is not used.
            arguments (Input)
                tag  % Tag without the leading "GFL".
            end
            arguments (Input, Repeating)
                varargin  % Options of Bus.add_component, passed on to Component; first the ignored parameter input when the subclass has no constructor.
            end
            arguments (Output)
                obj  % Grid-following inverter object.
            end
            if numel(varargin) == 2
                varargin(1) = [];
            end
            obj@Component("GFL"+tag, varargin{:})
        end
    end
end
