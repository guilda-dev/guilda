function parameter_error(obj, s_key, varargin) %#ok<INUSD>
% Raise a constructor message of Component.xml for a subclass in another folder.
%
% `msg` only accepts a caller in the folder of the ID, so the base classes of the models
% in the `component` package reach Component.xml through this method.
% "GeneratorQIgnored" is a warning; the other keys are errors.
%
% See also msg, component.generator.abstract
%
% <@Group> Queries and checks
    arguments (Input)
        obj
        s_key (1,1) string   % Key of the message in Component.xml.
    end
    arguments (Input, Repeating)
        varargin               % Values for the placeholders of the message.
    end

    if s_key == "GeneratorQIgnored"
        warning(msg("GUILDA:Component:GeneratorQIgnored", varargin{:}))
    else
        error(msg("GUILDA:Component:" + s_key, varargin{:}))
    end
end
