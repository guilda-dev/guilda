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
    properties(Abstract, Dependent) % Parameters
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
    properties(Access=protected) % Edit log
        % Edit state of the layer: "unset", "initialized" or "editted".
        str_editFlag (1,1) string {mustBeMember(str_editFlag,["unset","initialized","editted"])} = "unset"
    end
    properties(SetAccess=private) % Edit log
        % Log of edits made to the layer since the last initialize.
        % Columns: timestamp, ID, log message, tag, and the states before and after the edit.
        % <@Type> table (Nx6)
        tab_editLog = array2table(zeros(0,6),'VariableNames',{'timestamp','ID','log','tag','before','after'});
    end
    properties(SetAccess=protected, Hidden) % Edit log
        % True when the cached f_* function handles built by set_odefcn no longer match the parameters.
        % Set by log_edit on the owner of an edited "dynamics" parameter, and on every layer of
        % the network when its "base" parameter (Hz) is edited; cleared when set_odefcn rebuilds
        % the handles. check_edit rebuilds the handles of every layer with this flag at the start
        % of an analysis. Only Component, LocalController and GlobalController own handles.
        l_staleOdefcn (1,1) logical = false

        % True when the equilibrium set by initialize no longer matches the model.
        % Kept on PowerNetwork only. Set by log_edit for edits of "dynamics", "base" (baseMVA) and
        % "powerflow" parameters, topology changes and slack-bus changes; edits of the network Hz
        % and of "operation", "OPF" and "graph" parameters leave it unchanged. Cleared by
        % reset_edit (end of initialize). See edit_effect for the mapping.
        l_staleEquilibrium (1,1) logical = false
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
        % <@Type> string
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

        function handle_edit(obj, tab) %#ok
        % Called by log_edit on the top layer (PowerNetwork) with every edit
        % reported by its layers (tab: the tab_editLog row), so that the
        % network can keep network-wide rules; a child never writes its siblings.
        % PowerNetwork overrides this; other layers do nothing.
        end

        function rebuild_odefcn(obj)
        % Rebuild the f_* handle cache from the current parameters.
        % Layers that own handles (Component, LocalController, GlobalController)
        % override this; other layers have nothing to rebuild.
            obj.l_staleOdefcn = false;
        end
    end
    methods(Static, Hidden)
        function [l_odefcn, l_equilibrium] = edit_effect(str_logtag, str_log)
        % What an edit makes stale, from the "tag" and "log" columns of tab_editLog.
        %   tag                    f_* handles   equilibrium
        %   Parameter(dynamics)    stale         stale
        %   Parameter(base)        stale         stale     (PowerNetwork para_base: baseMVA;
        %                                                   marks every layer of the network)
        %   Parameter(base), Hz    stale         -         (log "edit Hz": the equilibrium does
        %                                                   not depend on the nominal frequency)
        %   Parameter(powerflow)   -             stale
        %   Topology               -             stale     (add_/remove_/replace_)
        %   Slack                  -             stale
        %   Parameter(operation)   -             -
        %   Parameter(OPF)         -             -
        %   Parameter(graph)       -             -
        %   OPF                    -             -         (set_opffcn / reset_opffcn)
            arguments
                str_logtag (1,1) string
                str_log    (1,1) string = ""
            end
            switch str_logtag
                case "Parameter(base)"
                    l_odefcn = true;  l_equilibrium = str_log ~= "edit Hz";
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

        function set.str_tag(obj,str_newtag)
            str_newtag = obj.validate_tag(str_newtag);
            obj.str_tag = str_newtag;
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