classdef abstract < Component
% Base class of the load models.
%
% A load connects to one bus. Its tag starts with `"L"`, and its default OPF cost is 0
% because a fixed load adds nothing to the cost. Add a load with `Bus.add_component` and
% the key `"load-impedance"`, `"load-power"`, `"load-current"` or `"load-ZIP"`. Powers
% follow the bus convention: `P` and `Q` are injected into the bus, so a consuming load
% has negative `P`. A load without dynamic parameters ignores the `parameter` argument of
% `add_component`; a load with dynamic parameters reads it in its own constructor
% (component.load.ZIP).
%
% <@Examples>
% ```matlab
% net = PowerNetwork();
% bus = net.add_bus();
% ld  = bus.add_component("load-power", "P", -0.8, "Q", -0.3);
% ld.tab_parameter.powerflow        % P = -0.8, Q = -0.3
% ```
%
% See also Component, Bus.add_component, component.load.impedance, component.load.power, component.load.current, component.load.ZIP

    methods
        function obj = abstract(tag, varargin)
            % Create the load and build its model functions.
            %
            % Subclasses call it with `tag`, the tag without the leading `"L"`,
            % and `varargin`, the name-value options of `Bus.add_component`.
            % A subclass without a constructor passes on the inputs of
            % `Bus.add_component`, whose `parameter` is not used by a load.
            arguments (Input)
                tag  % Tag without the leading "L".
            end
            arguments (Input, Repeating)
                varargin  % Options of Bus.add_component, passed on to Component; first the ignored parameter input when the subclass has no constructor.
            end
            arguments (Output)
                obj  % Load object.
            end
            if numel(varargin) == 2
                varargin(1) = [];
            end
            obj@Component("L"+tag, varargin{:})
        end
    end
end