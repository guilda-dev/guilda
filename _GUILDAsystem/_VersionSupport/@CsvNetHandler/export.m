function path = export(net, ModelName, opt)
% Write a network to a CSV model folder (v3 wrapper of net.export_csv).
%
% v3 entry point of the CSV export (deprecated: warns GUILDA:Deprecated:CsvNetHandlerExport).
% Writes the folder <savepath>/@<ModelName> with the class file <ModelName>.m by
% net.export_csv(fullfile(savepath, "@"+ModelName), Overwrite=Overwrite). Without
% savepath a folder dialog opens (as in v3); version is the constant ver of the class file.
%
% <@Deprecated>
% Use net.export_csv(fullfile(savepath, "@"+ModelName)) instead.
%
% See also PowerNetwork.export_csv
    arguments
        net               (1,1) PowerNetwork   % Network to write.
        ModelName         (1,1) string  {mustBeValidVariableName} = "PowerNetwork"+string(datetime("now","Format","uuuuMMdd_HHmmss"))   % Class name of the model.
        opt.version       (1,1) double  = 1   % Constant ver of the class file.
        opt.savepath      (1,1) string  {mustBeFolder} = uigetdir(fullfile(GUILDA.pwd,"_GUILDAexport"), "Select folder to save CSV folder")   % Parent folder of @ModelName.
        opt.Overwrite     (1,1) logical = false   % Replace an existing folder.
    end
    arguments (Output)
        path   % The written model folder.
    end
    Deprecated("CsvNetHandlerExport");
    path = net.export_csv(fullfile(opt.savepath, "@"+ModelName), Overwrite=opt.Overwrite, ClassFile=true);
    if opt.version ~= 1
        str_file = fullfile(path, ModelName + ".m");
        writelines(replace(string(fileread(str_file)), "ver = 1" + newline, "ver = " + string(opt.version) + newline), str_file);
    end
end
