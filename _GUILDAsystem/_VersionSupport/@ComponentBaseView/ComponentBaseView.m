classdef ComponentBaseView < handle
% Deprecated view of the removed Component property para_base (Hz).
%
% comp.para_base and comp.tab_parameter.base return this view so that old scripts keep
% working. The frequency is held by the network:
%
% - reading Hz returns comp.get_Hz() (warning GUILDA:Deprecated:ComponentBaseHz)
% - setting Hz sets net.tab_parameter.base.Hz of the network of the component (warning
%   GUILDA:Deprecated:ComponentBaseHzSet); it is an error when the component is not
%   attached to a network.
%
% The static methods hold the logic of the v3 compatibility hooks in Component.m:
% `add_column` adds the "base" column (this view) to comp.tab_parameter,
% `remove_column` drops it before `comp.tab_parameter = tab` is applied, and
% `check_assign` accepts only this view for `comp.para_base = value`.
%
% <@Deprecated>
% Use comp.get_Hz() to read the frequency and net.tab_parameter.base.Hz to set it.
%
% See also Component, PowerNetwork

    properties (Access=private)
        a_Comp  % Component whose para_base this view shows.
    end
    properties (Dependent) % Parameter
        Hz  % [Hz] Nominal frequency of the network of the component.
        tab_parameter  % One-column table with Hz.
    end

    methods
        function obj = ComponentBaseView(comp)
            % Create the view for the component comp.
            arguments (Input)
                comp  % Component whose para_base is viewed.
            end
            arguments (Output)
                obj   % View of the removed para_base.
            end
            obj.a_Comp = comp;
        end
        function Hz = get.Hz(obj)
            Deprecated("ComponentBaseHz");
            Hz = obj.a_Comp.get_Hz();
        end
        function tab = get.tab_parameter(obj)
            Deprecated("ComponentBaseHz");
            tab = table(obj.a_Comp.get_Hz(), 'VariableNames', "Hz");
        end
        function set.Hz(obj, val)
            bus = obj.a_Comp.a_Bus;
            if isempty(bus) || isempty(bus.a_PowerNetwork)
                error(msg("GUILDA:ComponentBaseView:ComponentBaseHzNoNetwork", char(string(obj.a_Comp.s_tag))));
            end
            net = bus.a_PowerNetwork;
            Deprecated("ComponentBaseHzSet", net.s_tag, val);
            net.para_base.Hz = val;
        end
        function set.tab_parameter(obj, val)
            obj.Hz = val.Hz;
        end
    end

    methods (Static)
        tp = add_column(comp, tp)
        tp = remove_column(tp)
        check_assign(val)
    end
end
