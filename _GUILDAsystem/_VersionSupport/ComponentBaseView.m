classdef ComponentBaseView < handle
% COMPONENTBASEVIEW deprecated view of the removed Component para_base (Hz).
%    comp.para_base and comp.tab_parameter.base return this view so that old
%    scripts keep working. The frequency is held by the network:
%      read  Hz -> comp.r_Hz (warning GUILDA:Deprecated:ComponentBaseHz)
%      set   Hz -> sets net.tab_parameter.base.Hz of the component's network
%                  (warning GUILDA:Deprecated:ComponentBaseHzSet); error when
%                  the component is not attached to a network.
    properties (Access=private)
        a_Comp
    end
    properties (Dependent)
        Hz
        tab_parameter
    end

    methods
        function obj = ComponentBaseView(comp)
            obj.a_Comp = comp;
        end
        function Hz = get.Hz(obj)
            Deprecated("ComponentBaseHz");
            Hz = obj.a_Comp.r_Hz;
        end
        function tab = get.tab_parameter(obj)
            Deprecated("ComponentBaseHz");
            tab = table(obj.a_Comp.r_Hz, 'VariableNames', "Hz");
        end
        function set.Hz(obj, val)
            bus = obj.a_Comp.a_Bus;
            if isempty(bus) || isempty(bus.a_PowerNetwork)
                error('GUILDA:Deprecated:ComponentBaseHzNoNetwork', '%s', ...
                      Deprecated("ComponentBaseHzNoNetwork", obj.a_Comp.str_tag));
            end
            net = bus.a_PowerNetwork;
            Deprecated("ComponentBaseHzSet", net.str_tag, val);
            net.para_base.Hz = val;
        end
        function set.tab_parameter(obj, val)
            obj.Hz = val.Hz;
        end
    end
end
