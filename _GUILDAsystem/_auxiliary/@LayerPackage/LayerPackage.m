classdef LayerPackage < handle
% <@Desc> 
% Abstract base class for layer hierarchy management in GUILDA.
% It centralizes parent/children relationships, tag handling, and edit logging.
% <@Role> 
% auxiliary
% <@Constructor> 
% This class is abstract and should not be instantiated directly.

    %% Abstract
    properties(Abstract, Dependent)
        % <@Desc> manage parameter related to any analyis.
        % <@Role> Parameter
        % <@Type> Parameter
        % <@Size> 1x1
        tab_parameter
    end


    %% Layer Structure
    properties(Abstract, Dependent, Access=protected)
        % <@Desc> manage hierarchical structure of layers.
        % <@Role> Layer Structure
        % <@Type> LayerPackage
        % <@Size> 1x1
        parent

        % <@Desc> manage hierarchical structure of layers.
        % <@Role> Layer Structure
        % <@Type> LayerPackage cell array
        % <@Size> Nx1
        children
    end
    %% Edit log
    properties(Access=protected)
        % <@Desc> Flag to indicate if the layer has been edited.
        % <@Role> Edit Log
        % <@Type> string
        % <@Size> 1x1
        str_editFlag (1,1) string {mustBeMember(str_editFlag,["unset","initialized","editted"])} = "unset"
    end
    properties(SetAccess=private)
        % <@Desc> Log of edits made to the layer, including timestamp, ID, log message, tag, and before/after states.
        % <@Role> Edit Log
        % <@Type> table
        % <@Size> Nx6
        tab_editLog = array2table(zeros(0,6),'VariableNames',{'timestamp','ID','log','tag','before','after'});
    end
    
    %% Tag
    properties(Access=protected)
        % <@Desc> Flag to indicate if the layer is managed by the tag system.
        % <@Role> Tag
        % <@Type> logical
        % <@Size> 1x1
        l_managedTag = true;
    end
    properties
        % <@Desc> User-defined tag for the layer, used for identification and management within the layer structure.
        % <@Role> Tag
        % <@Type> string
        % <@Size> 1x1
        str_tag
    end


    methods(Access=private)
        p = findparent(obj) 
        c = findchildren(obj)
        str_newtag = validate_tag(obj,str_newtag)
    end

    methods(Access=protected)
        log_edit(obj, log, time, tab)
        reset_edit(obj)
        flag = check_edit(obj)
    end
    methods
        varargout = disp_tree(obj,str_space,str_ignore,l_isfirst)
        out = get_tag(obj,l_with_layer, str_split)
        out = attach_tag(obj,str_name_list)
        [out, dict_cls] = struct(obj, l_disp, str_header, dict_cls)

        function set.str_tag(obj,str_newtag)
            str_newtag = obj.validate_tag(str_newtag);
            obj.str_tag = str_newtag;
        end
    end
    methods(Hidden)
        function tab = table(obj)
        % <@Desc> 
        % Returns the parameter table associated with this layer object.
        % <@Role> Parameter
        % <@Summary> Convert layer parameters into table format.
        % <@Signatures>
        % [
        %   "tab = table(obj)"
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
        %     "Name": "tab",
        %     "Type": "table",
        %     "Description": "Parameter table of the layer."
        %   }
        % ]
        % <@Examples>
        % [
        %   "```matlab\ntab = table(obj);\n```"
        % ]
            tab = obj.tab_parameter;
        end
        
        function str = string(obj)
        % <@Desc> 
        % Returns the tag string representation of this layer object.
        % <@Role> Tag
        % <@Summary> Convert the layer object to a tag string.
        % <@Signatures>
        % [
        %   "str = string(obj)"
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
        %     "Name": "str",
        %     "Type": "string",
        %     "Description": "Tag string of the layer object."
        %   }
        % ]
        % <@Examples>
        % [
        %   "```matlab\nstr = string(obj);\n```"
        % ]
            str = obj.str_tag;
        end
    end
end