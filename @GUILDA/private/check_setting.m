function [val, l_ok, s_expect] = check_setting(sct_set, val)
% Check a value against the definition of a setting and convert it to the stored class.
%
% The definition is one setting of @GUILDA/config/Default<Category>.json. Type gives the
% accepted values and the stored class:
%
% - "double": a real numeric or logical scalar (null of a JSON file: NaN), stored as double.
% - "logical": true, false, 1 or 0, stored as logical.
% - "select": text that is one of options, stored as a string. With FromLogical (the
%   options for false and true), true, false, 1 or 0 is stored as that option.
% - "string": text (a string array, a character vector or a cell array of character
%   vectors), stored as a string row.
%
% Valid (optional) is a condition on the stored value v, a MATLAB expression such as
% "v > 0 || isnan(v)". get_config checks the values of the user files with it (an invalid
% value is reset to the default) and GUILDA.setting the new values (an invalid value stops
% with an error).
    arguments (Input)
        sct_set (1,1) struct   % Definition of the setting: Value, Type, Description (and options, FromLogical, Valid).
        val                    % Value to check.
    end
    arguments (Output)
        val       % Value in the stored class.
        l_ok      % true when the value is valid.
        s_expect  % Description of the accepted values (for the messages).
    end
    switch sct_set.Type
        case "double"
            s_expect = "a real numeric scalar";
            if (isa(val, "missing") || isstring(val)) && isscalar(val) && ismissing(val)
                val = NaN;
            end
            l_ok = (isnumeric(val) || islogical(val)) && isscalar(val) && isreal(val);
            if l_ok, val = double(val); end
        case "logical"
            s_expect = "true or false";
            l_ok = (islogical(val) || isnumeric(val) && ismember(val, [0 1])) && isscalar(val);
            if l_ok, val = logical(val); end
        case "select"
            sv_opt   = string(sct_set.options);
            s_expect = "one of " + strjoin("""" + sv_opt(:)' + """", ", ");
            if isfield(sct_set, "FromLogical") && isscalar(val) && (islogical(val) || isnumeric(val) && ismember(val, [0 1]))
                sv_from = string(sct_set.FromLogical);
                val = sv_from(double(val) + 1);
            end
            l_ok = (ischar(val) && (isrow(val) || isempty(val)) || isstring(val) && isscalar(val)) ...
                   && ismember(string(val), sv_opt);
            if l_ok, val = string(val); end
        case "string"
            s_expect = "text (a string array, a character vector or a cell array of character vectors)";
            l_ok = isstring(val) && ~any(ismissing(val)) || ischar(val) && (isrow(val) || isempty(val)) || iscellstr(val);
            if l_ok, val = reshape(string(val), 1, []); end
        otherwise
            s_expect = "a value of type " + sct_set.Type;
            l_ok = false;
    end
    if isfield(sct_set, "Valid")
        s_expect = s_expect + " with " + sct_set.Valid;
        if l_ok
            f_valid = str2func("@(v) " + sct_set.Valid);
            l_ok = f_valid(val);
        end
    end
end
