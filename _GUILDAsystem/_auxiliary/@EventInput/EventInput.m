classdef (Sealed) EventInput < EventBase
% Values added to inputs of a component from t_start to t_end (Scenario.add_input).
%
% The value is a constant (one number per input, or one for all) or a time series: a
% matrix [t, v_1, ..., v_n] or a table with the variables Time and the input names (see
% Scenario.add_input). It is stored as a constant column (s_method "") or as the matrix of
% the series with its interpolation s_method ("zoh", "foh" or "spline"; "foh" when not
% given). In tab_input the input is one row. Its tag is Tag, or input<n> when Tag is
% empty. The constructor and edit check the form of the value
% (GUILDA:EventInput:InvalidInputTable, MethodWithoutSeries); the component, the input names,
% the number of values and the series are checked when the event is added to a scenario.
%
% <@Examples>
% ```matlab
% ev = sc.add_input("B002SG1", "Pmech", 0.05, [1, 1.5]);
% ev.edit(Value=[0, 0; 2, 0.02], Time=[1, 3]);      % a ramp; Method back to "foh"
% ```
%
% See also EventBase, Scenario.add_input

    properties (SetAccess={?EventBase}) % Input
        s_unit (1,1) string = ""               % Tag of the component.
        sv_name (:,1) string = strings(0,1)    % Names of the inputs (e.g. "Pmech"). <@Type> string
        rm_value double = zeros(0,1)           % Constants (a column: one per input or one for all), or a time series [t, v_1, ..., v_n].
        rr_time (1,2) double = [0, 0]          % [s] [t_start, t_end] of the input.
        s_method (1,1) string = ""             % Interpolation of a time series: "zoh", "foh" or "spline"; "" for constants.
    end

    properties (Constant, Hidden) % Kind
        s_prefix = "input"                     % Prefix of the automatic tag.
        s_table  = "input"                     % Table the event contributes to.
    end

    methods
        function obj = EventInput(unit, name, value, time, opt)
        % Create an input event (not in a scenario).
            arguments (Input)
                unit  (1,1) string                          % Tag of the component.
                name  (:,1) string                          % Names of the inputs (e.g. "Pmech", "Vfield").
                value {mustBeA(value, ["double","table"])}  % Constants (one per input or one for all), or a time series [t, v_1, ..., v_n] or table.
                time  (1,2) double                          % [s] [t_start, t_end] of the input.
                opt.Method (1,1) string {mustBeMember(opt.Method, ["zoh","foh","spline"])}  % Interpolation of a time series: "zoh", "foh" or "spline". Default: "foh".
                opt.Tag (1,1) string = ""                   % Tag of the input; "" for input<n> (not Fault or Parallel followed by digits).
            end
            arguments (Output)
                obj  % The new event.
            end
            s_method = "";
            if isfield(opt, "Method")
                s_method = opt.Method;
            end
            s_lbl = opt.Tag;
            if s_lbl == ""
                s_lbl = "EventInput";
            end
            [obj.rm_value, obj.s_method] = normalize_input(value, name, s_method, {char(s_lbl), '(none)'});
            obj.s_unit  = unit;
            obj.sv_name = name;
            obj.rr_time = time;
            obj.s_tag   = opt.Tag;
        end
    end

    methods (Access={?Scenario, ?EventBase})
        tab = table_rows(obj)
    end
end
