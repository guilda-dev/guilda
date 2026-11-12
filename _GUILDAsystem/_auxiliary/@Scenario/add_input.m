function s_tag = add_input(obj, unit, name, value, time, opt)
% Add values to inputs of a component from t_start to t_end.
%
% A value is a number or a function f(t) of the time since t_start; several inputs take
% a vector of numbers or a cell of numbers and functions.
%
% <@Examples>
% ```matlab
% sc.add_input("B002SG1", ["Pmech"; "Vfield"], {0.05; @(t) 0.01*t}, [1, 1.5]);
% ```
    arguments (Input)
        obj
        unit  (1,1) string % Tag of the component.
        name  (:,1) string % Names of the inputs (e.g. "Pmech", "Vfield").
        value (:,1) {mustBeA(value, {'double','cell','function_handle'})} % Values, one per input or one for all.
        time  (1,2) double % [s] [t_start, t_end] of the input.
        opt.Tag (1,1) string = "" % Tag of the disturbance; default input<n>.
    end
    arguments (Output)
        s_tag (1,1) string % Tag of the added disturbance.
    end
    d = blank_record(opt.Tag, time);
    d.InputUnit  = unit;
    d.InputName  = name;
    d.InputValue = value;
    s_tag = obj.add_record(d, "input");
end
