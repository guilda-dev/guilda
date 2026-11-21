function con = set_avr(obj, Key, opt)
% Attach the AVR of the generator by its model key and return it.
%
% Same as add_local_controller(Key, parameter=...) for a key whose role (s_role) is
% "avr"; a key of another role is rejected with an error
% (GUILDA:Component:ControllerRoleMismatch) and the generator is left as it was.
% A new AVR replaces the attached one, as in add_local_controller.
% gen.avr returns the attached AVR.
%
% <@Examples>
% ```matlab
% con = gen.set_avr("avr-ST1");
% gen.avr == con     % true
% ```
%
% See also Component.add_local_controller, component.generator.abstract
%
% <@Group> Construction and editing
    arguments (Input)
        obj
        Key           (1,:) char {tools.mustBeKeyOf(Key, "LocalController")}  % Local controller model key with the role "avr", e.g. "avr-ST1".
        opt.parameter {mustBeA(opt.parameter, ["struct","table"])} = struct()  % Constructor parameters (struct or one-row table of Name=Value); omitted ones use the class defaults.
    end
    arguments (Output)
        con  % Added LocalController object.
    end
    check_key_role(obj, Key, "avr", "set_avr");
    con = obj.add_local_controller(Key, parameter=opt.parameter);
end
