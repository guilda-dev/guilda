function set_variable(obj, s_name, value)
% Set a variable of the workspace the code runs in.
%
% <@Examples>
% ```matlab
% h.set_variable("net", network.IEEE9bus());
% ```
    arguments (Input)
        obj                                         % The log.
        s_name (1,1) string {mustBeValidVariableName}  % Variable name (not varargin or varargout).
        value                                       % Value of the variable.
    end
    arguments (Output)
    end
    if ismember(s_name, ["varargin", "varargout"])
        error(msg("GUILDA:HistoryGUILDA:ReservedName", s_name))
    end
    obj.sct_variable.(s_name) = value;
end
