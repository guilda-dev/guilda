function con = set_pss(obj, Key, opt)
% Attach the PSS of the generator by its model key and return it.
%
% Same as add_local_controller(Key, parameter=...) for a key whose role (s_role) is
% "pss"; a key of another role is rejected with an error
% (GUILDA:Component:ControllerRoleMismatch) and the generator is left as it was.
% The PSS goes under the AVR of the generator, so attach the AVR first.
% A new PSS replaces the attached one, as in add_local_controller.
% gen.pss returns the attached PSS.
%
% <@Examples>
% ```matlab
% gen.set_avr("avr-ST1");
% con = gen.set_pss("pss-PSS1");    % under the AVR
% gen.pss == con     % true
% ```
%
% See also Component.add_local_controller, component.generator.abstract
%
% <@Group> Construction and editing
    arguments (Input)
        obj
        Key           (1,:) char {tools.mustBeKeyOf(Key, "LocalController")}  % Local controller model key with the role "pss", e.g. "pss-PSS1".
        opt.parameter {mustBeA(opt.parameter, ["struct","table"])} = struct()  % Constructor parameters (struct or one-row table of Name=Value); omitted ones use the class defaults.
    end
    arguments (Output)
        con  % Added LocalController object.
    end
    check_key_role(obj, Key, "pss", "set_pss");
    con = obj.add_local_controller(Key, parameter=opt.parameter);
end
