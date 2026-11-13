function data = config(category,parameter,option)
% Return the GUILDA settings: all of them, one category, or the value of one setting.
%
% The settings are read once from @GUILDA/config (defaults) and @GUILDA/user (values of
% the user, written by GUILDA.setting) and kept until a setting changes. They are checked
% when they are read: each value has the class of its type (double, logical, string) and
% passes the condition of its definition; an invalid user value is reset to its default
% (INFO GUILDA:GUILDA:ConfigValueReset). An analysis therefore uses the value as it is,
% as the default of its Name-Value option or, for a setting without an option, where it
% is used.
%
% <@Examples>
% ```matlab
% GUILDA.config("OptimalPowerFlow", "Method")      % value of one setting
% sct = GUILDA.config("OptimalPowerFlow");         % Value, Type, Description of each setting
% ```
%
% See also GUILDA.setting
    arguments (Input)
        category     = []                % Configuration category (field of the config struct); empty returns everything.
        parameter    = []                % Parameter in the category; empty returns the whole category.
        option.reset (1,1) logical = false;  % Read the configuration files again instead of the cache.
    end
    arguments (Output)
        data  % Configuration struct, category struct, or the parameter value.
    end
    
    persistent cache
    if isempty(cache) || option.reset
        [cache, sv_reset, sm_invalid] = get_config();
        % after the cache is set: show_msg reads the Message settings through GUILDA.config
        for s_reset = sv_reset'
            show_msg("info", "GUILDA:GUILDA:ConfigReset", s_reset)
        end
        for k = 1:size(sm_invalid, 1)
            show_msg("info", "GUILDA:GUILDA:ConfigValueReset", sm_invalid(k,1), sm_invalid(k,2), sm_invalid(k,3))
        end
    end
    
    data = cache;
    if ~isempty(category)
        data = data.(category);
        if ~isempty(parameter)
            data = data.(parameter).Value;
        end
    end

end