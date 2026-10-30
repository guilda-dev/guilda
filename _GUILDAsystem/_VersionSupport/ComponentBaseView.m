classdef ComponentBaseView < handle
% Deprecated view of the removed Component property para_base (Hz).
%
% comp.para_base and comp.tab_parameter.base return this view so that old scripts keep
% working. The frequency is held by the network:
%
% - reading Hz returns comp.r_Hz (warning GUILDA:Deprecated:ComponentBaseHz)
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
% Use comp.r_Hz to read the frequency and net.tab_parameter.base.Hz to set it.
%
% See also Component, PowerNetwork

    properties (Access=private)
        a_Comp
    end
    properties (Dependent) % Parameter
        Hz              % [Hz] Nominal frequency of the network of the component.
        tab_parameter   % One-column table with Hz.
    end

    methods
        function obj = ComponentBaseView(comp)
            % Create the view for the component comp.
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

    methods (Static)
        function tp = add_column(comp, tp)
            % Return the tab_parameter of a component with the deprecated "base" column first.
            tp = [table(ComponentBaseView(comp), 'VariableNames', "base"), tp];
        end
        function tp = remove_column(tp)
            % Remove the "base" column from a tab_parameter table.
            %
            % "base" is this view (a handle): an edit of comp.tab_parameter.base.Hz
            % has already been forwarded to the network.
            if ismember("base", string(tp.Properties.VariableNames))
                tp = removevars(tp, "base");
            end
        end
        function check_assign(val)
            % Accept only this view for comp.para_base = value.
            %
            % comp.para_base.Hz = x is forwarded by the view itself (it is a handle).
            if ~isa(val, "ComponentBaseView")
                error('GUILDA:Deprecated:ComponentBaseHz', '%s', Deprecated("ComponentBaseHz"));
            end
        end
    end
end
