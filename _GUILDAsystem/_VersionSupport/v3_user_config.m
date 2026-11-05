function sct_user = v3_user_config(s_field, sct_user)
% Convert old keys of the user settings.
%
% v3 compatibility hook of the user settings (@GUILDA/user/Default*.json, read by
% get_config): renames the old keys into the v4 ones.
%   TimeSimulation.Reporter -> TimeSimulation.Progress (kept when Progress is also given)
% The startup writes the settings back (set_config), so an old file is converted once.
%
% Name-Value options:
%
% - `s_field` — Settings category (file name without Default and .json), e.g. "TimeSimulation".
% - `sct_user` — Contents of the user settings file.
    arguments (Output)
        sct_user % User settings with the v4 keys.
    end
    if s_field == "TimeSimulation" && isstruct(sct_user) && isfield(sct_user, "Reporter")
        if ~isfield(sct_user, "Progress")
            sct_user.Progress = sct_user.Reporter;
        end
        sct_user = rmfield(sct_user, "Reporter");
    end
end
