function write_user_config(s_category, sct_category)
% Write the values of one settings category to its user file in @GUILDA/user.
%
% The file gets the "version" field of the default file @GUILDA/config/Default<Category>.json
% (none when the default file has none), so that get_config keeps the values until the
% default version changes.
    arguments (Input)
        s_category   (1,1) string  % Category, e.g. "PowerFlowCalculation".
        sct_category struct        % Settings of the category (fields with Value, Type and Description).
    end
    s_file = "Default" + s_category + ".json";
    sct_def = readstruct(fullfile(GUILDA.pwd,"@GUILDA","config",s_file));
    sct = struct();
    if isfield(sct_def, "version")
        sct.version = sct_def.version;
    end
    for c = fieldnames(sct_category)'
        sct.(c{1}) = values_of(sct_category.(c{1}));
    end
    text = jsonencode(sct, PrettyPrint=true, ConvertInfAndNaN=false);
    writelines(text, fullfile(GUILDA.pwd,"@GUILDA","user",s_file))
end


function data = values_of(data)
    % Values of a setting (fields Value, Type, Description), or of a struct of settings
    if isstruct(data)
        if all( ismember(["Value","Type","Description"], fieldnames(data)) )
            data = data.Value;
        else
            for c = fieldnames(data)'
                data.(c{1}) = values_of(data.(c{1}));
            end
        end
    end
end
