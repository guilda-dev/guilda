function [out, sv_reset] = get_config(varargin)
% Read the GUILDA configuration (defaults merged with the user settings).
%
% Each category has a default file @GUILDA/config/Default<Category>.json and may have a
% user file @GUILDA/user/Default<Category>.json with the values of the user. When the
% "version" field of the user file differs from that of the default file (a user file
% without "version" included), the user values of that category are dropped: the user
% file is written again with the default values, and the category is returned in
% sv_reset so that the caller can tell the user (INFO GUILDA:GUILDA:ConfigReset).
    arguments (Input, Repeating)
        varargin  % Field names passed to getfield to select a part of the configuration.
    end
    arguments (Output)
        out       % Configuration struct, or the selected part of it.
        sv_reset  % Categories whose user settings were reset to the defaults (string column).
    end

    env_user = struct();
    env_sys  = struct();
    sv_reset = strings(0,1);

    for ele = config_files()'
        path_def_user  = fullfile(GUILDA.pwd,"@GUILDA","user"  ,ele);
        path_def_sys   = fullfile(GUILDA.pwd,"@GUILDA","config",ele);

        field = replace(ele,["Default",".json"],["",""]);
        [env_sys.(field), version_sys] = split_version(readstruct(path_def_sys));
        env_user.(field) = struct();
        if isfile(path_def_user)
            [sct_user, version_user] = split_version(readstruct(path_def_user));
            if isequal(version_user, version_sys)
                env_user.(field) = sct_user;
            else
                sv_reset(end+1,1) = field; %#ok<AGROW>
            end
        end
    end

    out   = merge_config(env_sys, env_user);
    for field = sv_reset'
        write_user_config(field, out.(field));
    end
    first = {'EnvStartup','Model'};
    out   = orderfields(out,[first,reshape(setdiff(fieldnames(out),first),1,[])]);
    if numel(varargin)>0
        out  = getfield(out,varargin{:});
    end
end


function [sct, version] = split_version(sct)
    % Take the "version" field out of the contents of a settings file ([] when absent)
    version = [];
    if isstruct(sct) && isfield(sct, "version")
        version = sct.version;
        sct     = rmfield(sct, "version");
    end
end
