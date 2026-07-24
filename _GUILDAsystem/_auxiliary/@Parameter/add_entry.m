function add_entry(obj,names,defaults,valids)
    % <@Desc>
    % Adds dynamic properties and attaches change listeners.
    % <@Role>
    % Parameter
    % <@Summary>
    % Register parameter names, defaults, and validation classes.
    % <@Signatures>
    % [
    %   "add_entry(obj, names, defaults, valids)"
    % ]
    % <@Parameters>
    % [
    %   {
    %     "Name": "obj",
    %     "Type": "Parameter",
    %     "Description": "Target parameter container.",
    %     "Required": true,
    %     "Default": "-"
    %   },
    %   {
    %     "Name": "names",
    %     "Type": "string array | cellstr",
    %     "Description": "Parameter names to register.",
    %     "Required": true,
    %     "Default": "-"
    %   },
    %   {
    %     "Name": "defaults",
    %     "Type": "cell array",
    %     "Description": "Default values for each parameter.",
    %     "Required": true,
    %     "Default": "-"
    %   },
    %   {
    %     "Name": "valids",
    %     "Type": "string array | cellstr",
    %     "Description": "Validation classes for each parameter.",
    %     "Required": true,
    %     "Default": "-"
    %   }
    % ]
    % <@Returns>
    % []
    arguments
        obj 
    end
    arguments(Input,Repeating)
        names    %(1,1) string {mustBeValidVariableName}
        defaults %(1,1) 
        valids   %(1,1) string
    end
    for i = 1:numel(names)
        name    = names{i};
        default = defaults{i};
        valid   = valids{i};
        
        obj.sv_parameter   = [obj.sv_parameter,name];
        dprop               = obj.addprop( name );
        dprop.SetObservable = true;
        obj.(name)          = default;
        
        addlistener(obj,name,'PreSet', @(~,event) obj.callbackPreSet(name,event));             % Befor Change: Save unchanged data to val_stash
        addlistener(obj,name,'PostSet', @(~,event) obj.callbackPostSet(name,valid,event));     % After Change: Validate / Compare changed data vs. val_stash / log 
    end
end