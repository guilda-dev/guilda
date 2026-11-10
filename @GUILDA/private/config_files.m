function sv_file = config_files()
% File names of the settings categories: the Default*.json files in @GUILDA/config.
    arguments (Output)
        sv_file  % File names, e.g. "DefaultPowerFlowCalculation.json" (string column).
    end
    sct     = dir(fullfile(GUILDA.pwd,"@GUILDA","config","Default*.json"));
    sv_file = string({sct.name}');
end
