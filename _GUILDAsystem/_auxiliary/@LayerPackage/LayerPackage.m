classdef LayerPackage < handle
% Abstract base class for layer hierarchy management in GUILDA.
%
% It centralizes parent/children relationships, tag handling, and edit logging (each layer
% reports its edits with log_edit; the network keeps them in PowerNetwork.tab_editLog). The
% network, buses, branches, components, controllers (through PowerSystemModel) and
% Parameter containers derive from it.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.disp_tree();            % hierarchy of the layers below the network
% bus = net.a_Bus{1};
% bus.get_tag(true, "/")      % tag including the parent layers
% net.tab_editLog             % edits since the last net.initialize (kept on the network)
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
    properties(SetAccess=protected, Hidden) % Edit log
        % Edit state of the layer, one struct with these fields (set.sct_edit checks them):
        %
        % - l_initialized: True once initialize has run with the layer in the network (set by
        %   reset_edit at the end of initialize).
        % - str_odefcn: State of the cached f_* function handles built by set_odefcn: "unset"
        %   (never built), "editted" (built, but no longer matching the parameters or the
        %   network frequency) or "updated" (built from the current values). An edit of a
        %   "dynamics" parameter (log_edit, on its owner), a network Hz edit (log_edit, on every
        %   layer of the network) and an attach (Component.set_bus, LocalController.set_parent,
        %   GlobalController.set_parent, on the attached subtree) turn "updated" into "editted";
        %   set_odefcn sets "updated". The handles are built when they are used: check_edit, at
        %   the start of an analysis, calls set_odefcn on every layer that is not "updated".
        %   Only Component, LocalController and GlobalController own handles.
        %
        % Whether the equilibrium is stale is not stored: PowerNetwork.l_staleEquilibrium
        % derives it from tab_editLog (see edit_effect).
        sct_edit (1,1) struct = struct("l_initialized",false, "str_odefcn","unset")
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
        % A rename is recorded in the network's tab_editLog (tag "Tag") and makes nothing stale. Tags are permanent
        % IDs, so the tags of existing child layers do not follow: after renaming bus B002 to BX, its
        % component SG1B002 keeps its tag and a component added later is SG2BX.
        % <@Type> string
        str_tag
    end


    methods(Access=protected)
        log_edit(obj, log, tag, before, after)
        reset_edit(obj)
        flag = check_edit(obj)

        function report_edit(obj, tab)
        % Pass an edit row built by log_edit up to the top layer (PowerNetwork), which
        % records it in tab_editLog and keeps network-wide rules. PowerNetwork overrides this.
            if isa(obj.parent,"LayerPackage")
                obj.parent.report_edit(tab);
            end
        end

        function set_odefcn(obj)
        % Build the f_* handle cache from the current parameters and network frequency.
        % Layers that own handles (Component, LocalController, GlobalController)
        % override this; other layers have nothing to build.
            obj.sct_edit.str_odefcn = "updated";
        end

        function mark_odefcn(obj)
        % Mark the built handles of the layer and its descendants as "editted", for a change
        % of the frequency they read: a network Hz edit (log_edit) and an attach
        % (Component.set_bus, LocalController.set_parent, GlobalController.set_parent).
        % check_edit builds them at the next analysis. Handles never built stay "unset".
            if obj.sct_edit.str_odefcn == "updated"
                obj.sct_edit.str_odefcn = "editted";
            end
            cellfun(@(c) c.mark_odefcn(), obj.children);
        end
    end
    methods(Hidden)
        function [lv_odefcn, lv_equilibrium] = edit_effect(obj, tab) %#ok<INUSL>
        % What each row of an edit log (tab_editLog) makes stale, from its "tag" and "log" columns.
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
        %   Initialize             -             stale     (initialize is writing the equilibrium;
        %                                                   the row is cleared when it finishes)
        %   Parameter(operation)   -             -
        %   Parameter(OPF)         -             -
        %   Parameter(graph)       -             -
        %   OPF                    -             -         (set_opffcn / reset_opffcn)
        %   Tag                    -             -         (rename through str_tag)
            arguments
                obj % Any layer (the mapping does not depend on it).
                tab table % Edit-log rows (columns of tab_editLog).
            end
            arguments (Output)
                lv_odefcn      % True for rows that make the handles of the parameter's owner stale (Nx1).
                lv_equilibrium % True for rows that make the equilibrium stale (Nx1).
            end
            sv_tag = string(tab.tag);
            lv_odefcn      = sv_tag == "Parameter(dynamics)";
            lv_equilibrium = ismember(sv_tag, ["Parameter(dynamics)", "Parameter(powerflow)", "Topology", "Slack", "Initialize"]) ...
                           | (sv_tag == "Parameter(base)" & string(tab.log) ~= "edit Hz");
        end
    end
    methods
        varargout = disp_tree(obj, str_ignore)
        out = get_tag(obj,l_with_layer, str_split)
        out = attach_tag(obj,str_name_list)
        [out, sct_visited] = struct(obj, l_disp, str_header, sct_visited)

        function set.sct_edit(obj, sct_edit)
            % A field cannot have a validator, and assigning a misspelled field would add a new one
            mustBeA(sct_edit.l_initialized, "logical");
            mustBeMember(sct_edit.str_odefcn, ["unset","editted","updated"]);
            assert(numel(fieldnames(sct_edit)) == 2, "GUILDA:LayerPackage:EditStateFields", "sct_edit has exactly two fields.");
            obj.sct_edit = sct_edit;
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