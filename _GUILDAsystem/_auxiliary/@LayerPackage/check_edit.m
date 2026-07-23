function flag = check_edit(obj)
% <@Desc>
% Checks the layer edit state and warns when edits remain unapplied.
% <@Role>
% Edit Log
% <@Summary>
% Validate whether the layer has an initialized edit state.
% <@Signatures>
% [
%   "flag = check_edit(obj)"
% ]
% <@Parameters>
% [
%   {
%     "Name": "obj",
%     "Type": "LayerPackage",
%     "Description": "Target layer object.",
%     "Required": true,
%     "Default": "-"
%   }
% ]
% <@Returns>
% [
%   {
%     "Name": "flag",
%     "Type": "logical scalar",
%     "Description": "True when state is initialized."
%   }
% ]
    flag = false; 
    switch obj.str_editFlag
        case "initialized"
            flag = true;
        case "editted"
            disp('Edit Log')
            disp(obj.tab_editLog)         
            warning('Some changes have been done to this class. This may cause them to be inconsistent when set up.')
        case "unset"
            error('Initialisation method has not been executed.')
    end
end