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
    properties(SetAccess=protected, Hidden)
        % <@Desc> True when the cached f_* function handles built by set_odefcn no longer
        % match the parameters. Set by log_edit on the owner of an edited "dynamics"
        % parameter, and on every layer of the network when its "base" parameter (Hz)
        % is edited; cleared when set_odefcn rebuilds the handles. check_edit
        % rebuilds the handles of every layer with this flag at the start of an analysis.
        % Only Component, LocalController and GlobalController own handles.
        % <@Role> Edit Log
        % <@Type> logical
        % <@Size> 1x1
        l_staleOdefcn (1,1) logical = false

        % <@Desc> True when the equilibrium set by initialize no longer matches the model.
        % Kept on PowerNetwork only. Set by log_edit for edits of "dynamics", "base" and
        % "powerflow" parameters, topology changes and slack-bus changes; edits of
        % "operation", "OPF" and "graph" parameters leave it unchanged. Cleared by
        % reset_edit (end of initialize). See edit_effect for the mapping.
        % <@Role> Edit Log
        % <@Type> logical
        % <@Size> 1x1
        l_staleEquilibrium (1,1) logical = false
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

        function Hz = get_Hz(obj)
        % Nominal frequency [Hz] of the network this layer belongs to (walks up
        % the parents; PowerNetwork overrides this). A layer not attached to a
        % network uses GUILDA.config("Model","Hz").
            p = obj.parent;
            if isa(p, "LayerPackage")
                Hz = p.get_Hz();
            else
                Hz = GUILDA.config("Model","Hz");
            end
        end

        function mark_stale_odefcn(obj)
        % Mark the f_* handles of this layer and all its descendants stale.
            obj.l_staleOdefcn = true;
            cellfun(@(c) c.mark_stale_odefcn, obj.children);
        end

        function rebuild_odefcn_tree(obj)
        % Rebuild the f_* handles of this layer and all its descendants now,
        % e.g. after attaching it to a parent whose network frequency may differ.
            obj.rebuild_odefcn();
            cellfun(@(c) c.rebuild_odefcn_tree, obj.children);
        end

        function rebuild_odefcn(obj)
        % Rebuild the f_* handle cache from the current parameters.
        % Layers that own handles (Component, LocalController, GlobalController)
        % override this; other layers have nothing to rebuild.
            obj.l_staleOdefcn = false;
        end
    end
    methods(Static, Hidden)
        function [l_odefcn, l_equilibrium] = edit_effect(str_logtag)
        % What an edit makes stale, from the "tag" column of tab_editLog.
        %   tag                    f_* handles   equilibrium
        %   Parameter(dynamics)    stale         stale
        %   Parameter(base)        stale         stale     (PowerNetwork para_base: Hz, baseMVA;
        %                                                   marks every layer of the network)
        %   Parameter(powerflow)   -             stale
        %   Topology               -             stale     (add_/remove_/replace_)
        %   Slack                  -             stale
        %   Parameter(operation)   -             -
        %   Parameter(OPF)         -             -
        %   Parameter(graph)       -             -
            switch str_logtag
                case {'Parameter(dynamics)', 'Parameter(base)'}
                    l_odefcn = true;  l_equilibrium = true;
                case {'Parameter(powerflow)', 'Topology', 'Slack'}
                    l_odefcn = false; l_equilibrium = true;
                otherwise
                    l_odefcn = false; l_equilibrium = false;
            end
        end
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