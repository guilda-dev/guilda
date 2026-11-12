function varargout = export(obj, varargin) %#ok<STOUT>
% Write the result to a file.
%
% Writes the result to a file. Each result class defines the file formats and
% Name-Value options. A result class without an export stops with
% GUILDA:ResultBase:Unsupported.
    arguments (Input)
        obj
    end
    arguments (Input, Repeating)
        varargin  % Output file, then Name-Value export options defined by the result class.
    end
    arguments (Output, Repeating)
        varargout % Path of the written file (defined by the result class).
    end
    obj.error_unsupported("export");
end
