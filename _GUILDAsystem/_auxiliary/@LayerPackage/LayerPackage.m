classdef LayerPackage < handle
% Abstract base class for layer hierarchy management in GUILDA.
%
% It centralizes parent/children relationships, tag handling, and edit logging. The
% network, buses, branches, components, controllers (through PowerSystemModel) and
% Parameter containers derive from it.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.disp_tree();            % hierarchy of the layers below the network
% bus = net.a_Bus{1};
% bus.get_tag(true, "/")      % tag including the parent layers
% net.tab_editLog             % edits since the last net.initialize
% ```
%
% See also PowerSystemModel, Parameter

    %% Abstract
    properties(Abstract, Dependent) % Parameter
        % Parameters of the layer used by the analyses.
        % <@Type> Parameter
        tab_parameter
    end


    %% Layer Structure
    properties(Abstract, Dependent, Access=protected) % Layer structure
        % Parent layer in the hierarchy.
        % <@Type> LayerPackage
        parent

        % Child layers in the hierarchy.
        % <@Type> LayerPackage cell array (Nx1)
        children
    end
    %% Edit log
    properties(SetAccess=private) % Edit log
        % Log of edits made to the layer since the last initialize.
        % Columns: timestamp, ID, log message, tag, and the states before and after the edit.
        % <@Type> table (Nx6)
        tab_editLog = array2table(zeros(0,6),'VariableNames',{'timestamp','ID','log','tag','before','after'});
    end
    properties(SetAccess=protected, Hidden) % Edit log
        % Edit state of the layer, one struct with these fields (set.s_edit checks them):
        %
        % - str_flag: "unset", "initialized" or "editted".
        % - str_odefcn: State of the cached f_* function handles built by set_odefcn: "unset"
        %   (never built), "editted" (built, but no longer matching the parameters or the
        %   network frequency) or "updated" (built from the current values). An edit of a
        %   "dynamics" parameter (log_edit, on its owner), a network Hz edit (log_edit, on every
        %   layer of the network) and an attach (Component.set_bus, LocalController.set_parent,
        %   GlobalController.set_parent, on the attached subtree) turn "updated" into "editted";
        %   set_odefcn sets "updated". The handles are built when they are used: check_edit, at
        %   the start of an analysis, calls set_odefcn on every layer that is not "updated".
        %   Only Component, LocalController and GlobalController own handles.
        % - l_staleEquilibrium: True when the equilibrium set by initialize no longer matches the
        %   model. Kept on PowerNetwork only. Set by log_edit for edits of "dynamics", "base"
        %   (baseMVA) and "powerflow" parameters, topology changes and slack-bus changes; edits of
        %   the network Hz and of "operation", "OPF" and "graph" parameters leave it unchanged.
        %   Cleared by reset_edit (end of initialize). See edit_effect for the mapping.
        s_edit (1,1) struct = struct("str_flag","unset", "str_odefcn","unset", "l_staleEquilibrium",false)
    end
    
    %% Tag
    properties(Access=protected) % Tag
        % True when the layer is managed by the tag system.
        % <@Type> logical
        l_managedTag = true;
    end
    properties % Tag
        % User-defined tag of the layer.
        % Used for identification within the layer structure; a tag that already exists among
        % the siblings is renamed with a number suffix.
        % A rename is recorded in tab_editLog (tag "Tag") and makes nothing stale. Tags are permanent
        % IDs, so the tags of existing child layers do not follow: after renaming bus B002 to BX, its
        % component SG1B002 keeps its tag and a component added later is SG2BX.
        % <@Type> string
        str_tag
    end


    methods(Access=protected)
        log_edit(obj, log, time, tab)
        reset_edit(obj)
        flag = check_edit(obj)

        function handle_edit(obj, tab) %#ok
        % Called by log_edit on the top layer (PowerNetwork) with every edit
        % reported by its layers (tab: the tab_editLog row), so that the
        % network can keep network-wide rules; a child never writes its siblings.
        % PowerNetwork overrides this; other layers do nothing.
        end

        function set_odefcn(obj)
        % Build the f_* handle cache from the current parameters and network frequency.
        % Layers that own handles (Component, LocalController, GlobalController)
        % override this; other layers have nothing to build.
            obj.s_edit.str_odefcn = "updated";
        end

        function mark_odefcn(obj)
        % Mark the built handles of the layer and its descendants as "editted", for a change
        % of the frequency they read: a network Hz edit (log_edit) and an attach
        % (Component.set_bus, LocalController.set_parent, GlobalController.set_parent).
        % check_edit builds them at the next analysis. Handles never built stay "unset".
            a_layer = {obj};
            while ~isempty(a_layer)
                if a_layer{1}.s_edit.str_odefcn == "updated"
                    a_layer{1}.s_edit.str_odefcn = "editted";
                end
                a_layer = [a_layer(2:end); reshape(a_layer{1}.children, [], 1)];
            end
        end
    end
    methods(Static, Hidden)
        function [l_odefcn, l_equilibrium] = edit_effect(str_logtag, str_log)
        % What an edit makes stale, from the "tag" and "log" columns of tab_editLog.
        %   tag                    f_* handles   equilibrium
        %   Parameter(dynamics)    stale         stale
        %   Parameter(base)        -             stale     (PowerNetwork para_base: baseMVA;
        %                                                   no model handle holds it)
        %   Parameter(base), Hz    -             -         (log "edit Hz": log_edit marks the
        %                                                   handles of every layer; the equilibrium
        %                                                   does not depend on the nominal frequency)
        %   Parameter(powerflow)   -             stale
        %   Topology               -             stale     (add_/remove_/replace_)
        %   Slack                  -             stale
        %   Parameter(operation)   -             -
        %   Parameter(OPF)         -             -
        %   Parameter(graph)       -             -
        %   OPF                    -             -         (set_opffcn / reset_opffcn)
        %   Tag                    -             -         (rename through str_tag)
            arguments
                str_logtag (1,1) string
                str_log    (1,1) string = ""
            end
            switch str_logtag
                case "Parameter(base)"
                    l_odefcn = false; l_equilibrium = str_log ~= "edit Hz";
                case "Parameter(dynamics)"
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

        function set.s_edit(obj, s_edit)
            % A field cannot have a validator, and assigning a misspelled field would add a new one
            mustBeMember(s_edit.str_flag, ["unset","initialized","editted"]);
            mustBeMember(s_edit.str_odefcn, ["unset","editted","updated"]);
            assert(numel(fieldnames(s_edit)) == 3, "GUILDA:LayerPackage:EditStateFields", "s_edit has exactly three fields.");
            obj.s_edit = s_edit;
        end

        function set.str_tag(obj,str_newtag)
            % A tag that already exists among the siblings gets a number suffix
            str_newtag = string(str_newtag);
            if obj.l_managedTag && ~isempty(obj.parent)
                a_sameLayer = obj.parent.children;
                l_me  = tools.vcellfun(@(a) a==obj, a_sameLayer);
                str_sameLayer = string( a_sameLayer(~l_me) );
                if any(str_sameLayer==str_newtag)
                    id = 2;
                    str_modified = str_newtag+num2str(id,"%.3d");
                    while ismember(str_modified, str_sameLayer)
                        id = id+1;
                        str_modified = str_newtag+num2str(id,"%.3d");
                    end
                    fprintf("Info : Tag changed due to overlaps detected")
                    disp(['[ "',char(str_newtag),'" >> "',char(str_modified),'"]'])
                    str_newtag = str_modified;
                end
            end
            str_oldtag = obj.str_tag;
            obj.str_tag = str_newtag;
            % The first assignment (constructor) is not a rename.
            if ~isempty(str_oldtag) && str_oldtag ~= str_newtag
                obj.log_edit("rename " + str_oldtag + " -> " + str_newtag, "Tag", str_oldtag, str_newtag);
            end
        end
    end
    methods(Hidden)
        function tab = table(obj)
        % Convert layer parameters into table format.
        %
        % Returns the parameter table associated with this layer object.
        %
        % <@Examples>
        % ```matlab
        % tab = table(obj);
        % ```
            arguments (Output)
                tab % Parameter table of the layer.
            end
            tab = obj.tab_parameter;
        end
        
        function str = string(obj)
        % Convert the layer object to a tag string.
        %
        % Returns the tag string representation of this layer object.
        %
        % <@Examples>
        % ```matlab
        % str = string(obj);
        % ```
            arguments (Output)
                str % Tag string of the layer object.
            end
            str = obj.str_tag;
        end
    end
end