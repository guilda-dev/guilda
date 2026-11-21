function [sct_def, sv_invalid] = merge_config(sct_def, sct_user)
% Apply the user values of one settings category to its default settings.
%
% Each user value is checked and converted by check_setting (type, options, Valid). An
% invalid value keeps the default and its setting is returned in sv_invalid with the
% accepted values, so that get_config writes the user file again and the caller tells
% the user (INFO GUILDA:GUILDA:ConfigValueReset). A user value of an unknown setting is
% dropped.
    arguments (Input)
        sct_def   struct  % Default settings of the category (fields with Value, Type and Description).
        sct_user  struct  % User values of the category read from @GUILDA/user.
    end
    arguments (Output)
        sct_def     % Default settings with the valid user values applied.
        sv_invalid  % Settings whose user value is invalid, and the accepted values (n x 2 string).
    end
    sv_invalid = strings(0,2);
    for s_name = string(fieldnames(sct_user)).'
        if ~isfield(sct_def, s_name)
            disp("Remove unknown environment field '"+s_name+"'." )
            continue
        end
        [val, l_ok, s_expect] = check_setting(sct_def.(s_name), sct_user.(s_name));
        if l_ok
            sct_def.(s_name).Value = val;
        else
            sv_invalid(end+1,:) = [s_name, s_expect]; %#ok<AGROW>
        end
    end
end
