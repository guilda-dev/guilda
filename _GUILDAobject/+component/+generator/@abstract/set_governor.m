function con = set_governor(obj, Key, opt)
% Attach the governor of the generator by its model key and return it.
%
% Same as add_local_controller(Key, parameter=...) for a key whose role (s_role) is
% "governor"; a key of another role is rejected with an error
% (GUILDA:Component:ControllerRoleMismatch) and the generator is left as it was.
% A new governor replaces the attached one, as in add_local_controller.
% gen.governor returns the attached governor.
%
% <@Examples>
% ```matlab
% con = gen.set_governor("gov-LPT1");
% gen.governor == con     % true
% ```
%
% See also Component.add_local_controller, component.generator.abstract
%
% <@Group> Construction and editing
    arguments (Input)
        obj
        Key           (1,:) char {tools.mustBeKeyOf(Key, "LocalController")}  % Local controller model key with the role "governor", e.g. "gov-LPT1".
        opt.parameter {mustBeA(opt.parameter, ["struct","table"])} = struct()  % Constructor parameters (struct or one-row table of Name=Value); omitted ones use the class defaults.
    end
    arguments (Output)
        con  % Added LocalController object.
    end
    check_key_role(obj, Key, "governor", "set_governor");
    con = obj.add_local_controller(Key, parameter=opt.parameter);
end
