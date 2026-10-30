classdef abstract < Component
% Base class of the load models.
%
% A load connects to one bus and has no dynamic parameters. Its tag starts with
% `"L"`, and its default OPF cost is 0 because a fixed load adds nothing to the cost.
% Add a load with `Bus.add_component` and the key `"load-impedance"` or
% `"load-power"`. Powers follow the bus convention: `P` and `Q` are injected into the
% bus, so a consuming load has negative `P`.
%
% <@Examples>
% ```matlab
% net = PowerNetwork();
% bus = net.add_bus();
% ld  = bus.add_component("load-power", "P", -0.8, "Q", -0.3);
% ld.tab_parameter.powerflow        % P = -0.8, Q = -0.3
% ```
%
% See also Component, Bus.add_component, component.load.impedance, component.load.power

    methods
        function obj = abstract(tag, varargin)
            % Create the load and build its model functions.
            %
            % Subclasses call it with `tag`, the tag without the leading `"L"`,
            % and `varargin`, the name-value options of `Bus.add_component`.
            obj@Component("L"+tag, varargin{:})
            obj.set_odefcn(obj.r_Hz)    % network Hz once attached (set_bus rebuilds)
        end
    end
end