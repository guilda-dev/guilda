function obj = loadobj(obj)
% A MAT file does not hold listeners: restore those of the parameters so that
% edits of a loaded network are checked and reported. MATLAB turns an error here
% into a warning, so an incomplete restore is reported as a warning.
%
% <@Group> Data IO
    arguments (Input)
        obj   % Network read from the MAT file.
    end
    arguments (Output)
        obj   % Network with the listeners of its parameters restored.
    end
    if ~restore_parameter_listeners(obj)
        warning(msg("GUILDA:PowerNetwork:IncompleteLoad", obj.s_tag))
    end
end
