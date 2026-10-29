function path = export(net, ModelName, opt)
% <@Desc>
% v3 entry point of the CSV export (deprecated: warns GUILDA:Deprecated:CsvNetHandlerExport).
% Writes the folder <savepath>/@<ModelName> with the class file <ModelName>.m by
% net.export_csv(fullfile(savepath, "@"+ModelName), Overwrite=Overwrite). Without
% savepath a folder dialog opens (as in v3); version is the constant ver of the class file.
% <@Role> Compatibility
% <@Summary> v3 wrapper of net.export_csv.
% <@Signatures>
% [
%   "path = CsvNetHandler.export(net, ModelName, Name, Value)"
% ]
% <@Parameters>
% [
%   {"Name": "net", "Type": "PowerNetwork", "Description": "Network to write.", "Required": true, "Default": "-"},
%   {"Name": "ModelName", "Type": "string scalar", "Description": "Class name of the model.", "Required": false, "Default": "\"PowerNetwork\" + date and time"},
%   {"Name": "savepath", "Type": "string scalar", "Description": "Parent folder of @ModelName.", "Required": false, "Default": "folder dialog"},
%   {"Name": "Overwrite", "Type": "logical scalar", "Description": "Replace an existing folder.", "Required": false, "Default": "false"},
%   {"Name": "version", "Type": "double scalar", "Description": "Constant ver of the class file.", "Required": false, "Default": "1"}
% ]
% <@Returns>
% [
%   {"Name": "path", "Type": "string scalar", "Description": "The written model folder."}
% ]
    arguments
        net               (1,1) PowerNetwork
        ModelName         (1,1) string  {mustBeValidVariableName} = "PowerNetwork"+string(datetime("now","Format","uuuuMMdd_HHmmss"))
        opt.version       (1,1) double  = 1
        opt.savepath      (1,1) string  {mustBeFolder} = uigetdir(fullfile(GUILDA.pwd,"_GUILDAexport"), "Select folder to save CSV folder")
        opt.Overwrite     (1,1) logical = false
    end
    Deprecated("CsvNetHandlerExport");
    path = net.export_csv(fullfile(opt.savepath, "@"+ModelName), Overwrite=opt.Overwrite, ClassFile=true);
    if opt.version ~= 1
        str_file = fullfile(path, ModelName + ".m");
        writelines(replace(string(fileread(str_file)), "ver = 1" + newline, "ver = " + string(opt.version) + newline), str_file);
    end
end
