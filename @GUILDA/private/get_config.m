function [out, sv_reset, sm_invalid] = get_config(varargin)
% Read the GUILDA configuration (defaults merged with the user settings).
%
% Each category has a default file @GUILDA/config/Default<Category>.json and may have a
% user file @GUILDA/user/Default<Category>.json with the values of the user. When the
% "version" field of the user file differs from that of the default file (a user file
% without "version" included), the user values of that category are dropped: the user
% file is written again with the default values, and the category is returned in
% sv_reset so that the caller can tell the user (INFO GUILDA:GUILDA:ConfigReset).
% Otherwise each user value is checked and converted to the class of its type by
% check_setting (merge_config): an invalid value is replaced by its default in the same
% way, returned in sm_invalid (INFO GUILDA:GUILDA:ConfigValueReset). The values are
% therefore of the class of their type (double, logical, string) and pass the condition
% Valid of their definition.
    arguments (Input, Repeating)
        varargin  % Field names passed to getfield to select a part of the configuration.
    end
    arguments (Output)
        out         % Configuration struct, or the selected part of it.
        sv_reset    % Categories whose user settings were reset to the defaults (string column).
        sm_invalid  % Settings whose invalid user value was reset: category, name, accepted values (n x 3 string).
    end

    out        = struct();
    sv_reset   = strings(0,1);
    sm_invalid = strings(0,3);

    for ele = config_files()'
        path_def_user  = fullfile(GUILDA.pwd,"@GUILDA","user"  ,ele);
        path_def_sys   = fullfile(GUILDA.pwd,"@GUILDA","config",ele);

        field = replace(ele,["Default",".json"],["",""]);
        [out.(field), version_sys] = split_version(readstruct(path_def_sys));
        if isfile(path_def_user)
            [sct_user, version_user] = split_version(readstruct(path_def_user));
            if isequal(version_user, version_sys)
                [out.(field), sv_invalid] = merge_config(out.(field), sct_user);
                sm_invalid = [sm_invalid; repmat(field, size(sv_invalid,1), 1), sv_invalid]; %#ok<AGROW>
                l_write = ~isempty(sv_invalid);
            else
                sv_reset(end+1,1) = field; %#ok<AGROW>
                l_write = true;
            end
            if l_write
                write_user_config(field, out.(field));   % the next read finds no reset
            end
        end
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
