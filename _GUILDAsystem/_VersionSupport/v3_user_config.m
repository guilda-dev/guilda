function s_user = v3_user_config(str_field, s_user)
% Convert old keys of the user settings.
%
% v3 compatibility hook of the user settings (@GUILDA/user/Default*.json, read by
% get_config): renames the old keys into the v4 ones.
%   TimeSimulation.Reporter -> TimeSimulation.Progress (kept when Progress is also given)
% The startup writes the settings back (set_config), so an old file is converted once.
%
% Name-Value options:
%
% - `str_field` — Settings category (file name without Default and .json), e.g. "TimeSimulation".
% - `s_user` — Contents of the user settings file.
    arguments (Output)
        s_user   % User settings with the v4 keys.
    end
    if str_field == "TimeSimulation" && isstruct(s_user) && isfield(s_user, "Reporter")
        if ~isfield(s_user, "Progress")
            s_user.Progress = s_user.Reporter;
        end
        s_user = rmfield(s_user, "Reporter");
    end
end
