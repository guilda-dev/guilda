function parameter_error(obj, str_key, varargin) %#ok<INUSD>
% Raise a constructor message of Component.xml for a subclass in another folder.
%
% `msg` only accepts a caller in the folder of the ID, so the base classes of the models
% in the `component` package reach Component.xml through this method.
% "GeneratorQIgnored" is a warning; the other keys are errors.
%
% Inputs:
% - `str_key`: key of the message in Component.xml.
% - `varargin`: values for the placeholders of the message.
%
% See also msg, component.generator.abstract
    arguments
        obj
        str_key (1,1) string   % Key of the message in Component.xml.
    end
    arguments (Repeating)
        varargin               % Values for the placeholders of the message.
    end

    str_id = char("GUILDA:Component:"+str_key);
    if str_key == "GeneratorQIgnored"
        warning(str_id, '%s', msg(str_id, varargin{:}))
    else
        error(str_id, '%s', msg(str_id, varargin{:}))
    end
end
