function s_user = v3_user_config(str_field, s_user)
% <@Desc>
% v3 compatibility hook of the user settings (@GUILDA/user/Default*.json, read by
% get_config): renames the old keys into the v4 ones.
%   TimeSimulation.Reporter -> TimeSimulation.Progress (kept when Progress is also given)
% The startup writes the settings back (set_config), so an old file is converted once.
% <@Role> Compatibility
% <@Summary> Convert old keys of the user settings.
% <@Signatures>
% [
%   "s_user = v3_user_config(str_field, s_user)"
% ]
% <@Parameters>
% [
%   {"Name": "str_field", "Type": "string scalar", "Description": "Settings category (file name without Default and .json), e.g. \"TimeSimulation\".", "Required": true, "Default": "-"},
%   {"Name": "s_user", "Type": "struct", "Description": "Contents of the user settings file.", "Required": true, "Default": "-"}
% ]
% <@Returns>
% [
%   {"Name": "s_user", "Type": "struct", "Description": "User settings with the v4 keys."}
% ]
    if str_field == "TimeSimulation" && isstruct(s_user) && isfield(s_user, "Reporter")
        if ~isfield(s_user, "Progress")
            s_user.Progress = s_user.Reporter;
        end
        s_user = rmfield(s_user, "Reporter");
    end
end
