function sct_user = v3_user_config(s_field, sct_user)
% Convert old keys of the user settings.
%
% v3 compatibility hook of the user settings (@GUILDA/user/Default*.json, read by
% get_config): renames the old keys into the v4 ones.
%   TimeSimulation.Reporter -> TimeSimulation.Progress (kept when Progress is also given)
%   PowerFlowCalculation: MaxIterations -> MaxIteration, UseParallel -> FsolveUseParallel,
%   MaxFunEvals -> FsolveMaxFunEvals (the new key wins when both are given); Display is
%   removed; Tolerance 0 (the old "default of the method") is removed, so the
%   default applies
% The startup writes the settings back (set_config), so an old file is converted once.
    arguments (Input)
        s_field   % Settings category (file name without Default and .json), e.g. "TimeSimulation".
        sct_user  % Contents of the user settings file.
    end
    arguments (Output)
        sct_user % User settings with the v4 keys.
    end
    if s_field == "TimeSimulation" && isstruct(sct_user) && isfield(sct_user, "Reporter")
        if ~isfield(sct_user, "Progress")
            sct_user.Progress = sct_user.Reporter;
        end
        sct_user = rmfield(sct_user, "Reporter");
    end
    if s_field == "PowerFlowCalculation" && isstruct(sct_user)
        sct_user = rename(sct_user, ["MaxIterations","UseParallel","MaxFunEvals"], ...
                                    ["MaxIteration","FsolveUseParallel","FsolveMaxFunEvals"]);
        sct_user = rmfield(sct_user, intersect("Display", string(fieldnames(sct_user))));
        if isfield(sct_user, "Tolerance") && isnumeric(sct_user.Tolerance) && isequal(sct_user.Tolerance, 0)
            sct_user = rmfield(sct_user, "Tolerance");
        end
    end
end


function sct = rename(sct, sv_old, sv_new)
% Renames the keys sv_old to sv_new; a key given in both forms keeps the new one
    for k = 1:numel(sv_old)
        if isfield(sct, sv_old(k))
            if ~isfield(sct, sv_new(k))
                sct.(sv_new(k)) = sct.(sv_old(k));
            end
            sct = rmfield(sct, sv_old(k));
        end
    end
end
