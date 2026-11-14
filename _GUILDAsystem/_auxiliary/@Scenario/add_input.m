function s_tag = add_input(obj, unit, name, value, time, opt)
% Add values to inputs of a component from t_start to t_end.
%
% One row is added to tab_input.
%
% The value is a constant or a time series:
%
% - Constant: one number per input, or one for all.
% - Time series: a matrix [t, v_1, ..., v_n] with one column per input, or a table with
%   the variables Time and the input names. t is the time since t_start [s]: finite,
%   strictly increasing and starting at 0. Method chooses the interpolation between the
%   points: "zoh" (hold the value until the next point), "foh" (linear, the default) or
%   "spline"; after the last point the last value is kept until t_end. A "zoh" series
%   with many points makes the simulation slower.
%
% Method given for a constant stops with GUILDA:Scenario:MethodWithoutSeries.
%
% <@Examples>
% ```matlab
% sc.add_input("B002SG1", ["Pmech"; "Vfield"], [0.05; 0.01], [1, 1.5]);   % constants
% sc.add_input("B002SG1", "Pmech", [0, 0; 2, 0.02], [1, 3]);               % ramp from t = 1 to 3
% sc.add_input("B002SG1", "Pmech", [0, 0.1; 1, 0], [1, 3], Method="zoh");  % 0.1 for 1 s, then 0
% ```
    arguments (Input)
        obj
        unit  (1,1) string % Tag of the component.
        name  (:,1) string % Names of the inputs (e.g. "Pmech", "Vfield").
        value {mustBeA(value, ["double","table"])} % Constants (one per input or one for all), or a time series [t, v_1, ..., v_n] or table.
        time  (1,2) double % [s] [t_start, t_end] of the input.
        opt.Method (1,1) string {mustBeMember(opt.Method, ["zoh","foh","spline"])} % Interpolation of a time series: "zoh", "foh" or "spline". Default: "foh".
        opt.Tag (1,1) string = "" % Tag of the disturbance; default input<n> (not Fault or Parallel followed by digits).
    end
    arguments (Output)
        s_tag (1,1) string % Tag of the added disturbance.
    end
    d = blank_record(opt.Tag, time);
    d.InputUnit  = unit;
    d.InputName  = name;
    d.InputValue = value;
    if isfield(opt, "Method")
        d.InputMethod = opt.Method;
    end
    s_tag = obj.add_record(d, "input");
end
