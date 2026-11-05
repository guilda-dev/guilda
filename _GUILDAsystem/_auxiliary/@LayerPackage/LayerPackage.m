classdef LayerPackage < handle
% Abstract base class for layer hierarchy management in GUILDA.
%
% It centralizes parent/children relationships, tag handling, and the edit log: each layer
% records its own edits with log_edit (the edits of a Parameter container on its owner)
% once it has been initialized, and tab_editLog of a layer collects the edits of the layer
% and its subtree. The network, buses, branches, components, controllers (through
% PowerSystemModel) and Parameter containers derive from it.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.disp_tree();            % hierarchy of the layers below the network
% net.a_Bus{1}.doc();         % class reference page of the first bus
% net.tab_editLog             % edits since the last net.initialize
% net.a_Bus{1}.tab_editLog    % only the edits of the first bus and the layers below it
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
        % - s_odefcn: State of the cached f_* function handles built by set_odefcn: "unset"
        %   (never built), "editted" (built, but no longer matching the parameters or the
        %   network frequency) or "updated" (built from the current values). An edit of a
        %   "dynamics" parameter (log_edit, on its owner), a network Hz edit (log_edit, on every
        %   layer of the network) and an attach (Component.set_bus, LocalController.set_parent,
        %   GlobalController.set_parent, on the attached subtree) turn "updated" into "editted";
        %   set_odefcn sets "updated". The handles are built when they are used: check_edit, at
        %   the start of an analysis, calls set_odefcn on every layer that is not "updated".
        %   Only Component, LocalController and GlobalController own handles.
        %
        % Whether the equilibrium is stale is kept by the network (PowerNetwork.l_staleEquilibrium,
        % from the edits reported to it; see edit_effect).
        sct_edit (1,1) struct = struct("l_initialized",false, "s_odefcn","unset")
    end
    properties(Dependent) % Edit log
        % Edits since the last initialize of the layer and of every layer below it (children,
        % recursively), in the order they were made: net.tab_editLog shows every edit of the
        % network, bus.tab_editLog only those of the bus, its components and their controllers.
        % Columns: timestamp ("uuuu/MM/dd HH:mm:ss"), ID (tags from the edited layer up, joined
        % by "/"), log message, tag (kind of edit, see edit_effect), states before and after.
        % Each layer keeps its own rows once it has been initialized; initialize clears them
        % (reset_edit), and so does attaching the layer to a new parent (clear_edit_log).
        % Built when read.
        % <@Type> table (Nx6) <@Stale> nothing
        tab_editLog
    end
    properties(Access=private, Hidden) % Edit log storage
        % Columns of the layer's own edits, filled by log_edit (store_edit) and read through
        % tab_editLog. Rows 1:n_editLog are in use; the columns grow by doubling, so an edit
        % is written in place. No validators: they would check the whole column on each edit.
        n_editLog    = 0;             % Number of rows in use.
        rv_editSeq   = zeros(0,1);    % Order of each edit among all layers (next_edit_seq).
        rv_editTime  = zeros(0,1);    % Time of each edit (datenum of now; formatted when read).
        sv_editID    = strings(0,1);  % ID column.
        sv_editLog   = strings(0,1);  % log column.
        sv_editTag   = strings(0,1);  % tag column.
        c_editBefore = cell(0,1);     % before column.
        c_editAfter  = cell(0,1);     % after column.
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
        s_tag
    end


    methods(Access=protected)
        out = get_tag(obj,l_with_layer, s_split)
        log_edit(obj, log, tag, before, after)
        reset_edit(obj)
        flag = check_edit(obj)

        function top = get_top_layer(obj)
        % Top layer of the hierarchy the layer belongs to: the first layer up the parents
        % without a LayerPackage parent (the layer itself when it has none).
            arguments (Input)
                obj
            end
            arguments (Output)
                top % Top layer (LayerPackage).
            end
            top = obj;
            a_parent = top.parent;
            while isa(a_parent,"LayerPackage")
                top = a_parent;
                a_parent = top.parent;
            end
        end

        function report_edit(obj, a_layer, tag, l_equilibrium) %#ok<INUSD>
        % Tell the top layer of the hierarchy about an edit (log_edit calls this on it), for
        % the rules of the whole hierarchy. Nothing is stored here; PowerNetwork overrides
        % this (slack rule, equilibrium state).
            arguments (Input)
                obj            % Top layer.
                a_layer        % Edited layer.
                tag            % Kind of edit (see edit_effect).
                l_equilibrium  % True when the edit makes the equilibrium stale (edit_effect).
            end
        end

        function clear_edit_log(obj)
        % Remove the edits of the layer and of every layer below it. Called when a layer is
        % attached to a new parent (Component.set_bus, LocalController.set_parent,
        % GlobalController.set_parent, Bus/Branch.set_network), so edits made elsewhere do
        % not show in the new hierarchy.
            arguments (Input)
                obj
            end
            obj.clear_edit_rows();
            cellfun(@(c) c.clear_edit_log(), obj.children);
        end

        function set_odefcn(obj)
        % Build the f_* handle cache from the current parameters and network frequency.
        % Layers that own handles (Component, LocalController, GlobalController)
        % override this; other layers have nothing to build.
            arguments (Input)
                obj
            end
            obj.sct_edit.s_odefcn = "updated";
        end

        function mark_odefcn(obj)
        % Mark the built handles of the layer and its descendants as "editted", for a change
        % of the frequency they read: a network Hz edit (log_edit) and an attach
        % (Component.set_bus, LocalController.set_parent, GlobalController.set_parent).
        % check_edit builds them at the next analysis. Handles never built stay "unset".
            arguments (Input)
                obj
            end
            if obj.sct_edit.s_odefcn == "updated"
                obj.sct_edit.s_odefcn = "editted";
            end
            cellfun(@(c) c.mark_odefcn(), obj.children);
        end
    end
    methods(Access=private)
        function store_edit(obj, a_layer, log, tag, before, after)
        % Append one edit to the layer's own rows (log_edit).
            arguments (Input)
                obj      % Layer that keeps the row.
                a_layer  % Edited layer (its tags give the ID column).
                log      % Log message.
                tag      % Kind of edit (see edit_effect).
                before   % State before the edit.
                after    % State after the edit.
            end
            n = obj.n_editLog + 1;
            if n > numel(obj.rv_editTime)
                n_size = max(16, 2*numel(obj.rv_editTime));
                obj.rv_editSeq(n_size,1)   = 0;
                obj.rv_editTime(n_size,1)  = 0;
                obj.sv_editID(n_size,1)    = "";
                obj.sv_editLog(n_size,1)   = "";
                obj.sv_editTag(n_size,1)   = "";
                obj.c_editBefore{n_size,1} = [];
                obj.c_editAfter{n_size,1}  = [];
            end
            obj.rv_editSeq(n)   = next_edit_seq();
            obj.rv_editTime(n)  = now;
            obj.sv_editID(n)    = a_layer.get_tag(true,"/");
            obj.sv_editLog(n)   = log;
            obj.sv_editTag(n)   = tag;
            obj.c_editBefore{n} = before;
            obj.c_editAfter{n}  = after;
            obj.n_editLog       = n;
        end

        function clear_edit_rows(obj)
        % Remove the layer's own rows (reset_edit, clear_edit_log).
            arguments (Input)
                obj
            end
            if obj.n_editLog == 0 && isempty(obj.rv_editTime)
                return
            end
            obj.n_editLog    = 0;
            obj.rv_editSeq   = zeros(0,1);
            obj.rv_editTime  = zeros(0,1);
            obj.sv_editID    = strings(0,1);
            obj.sv_editLog   = strings(0,1);
            obj.sv_editTag   = strings(0,1);
            obj.c_editBefore = cell(0,1);
            obj.c_editAfter  = cell(0,1);
        end
    end
    methods(Access=protected)
        function [lv_odefcn, lv_equilibrium] = edit_effect(obj, sv_tag, sv_log) %#ok<INUSL>
        % What each edit-log row makes stale, from its "tag" and "log" columns (one edit in
        % log_edit, the rows of tab_editLog in PowerNetwork.check_edit and initialize).
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
        %   Tag                    -             -         (rename through s_tag)
            arguments (Input)
                obj            % Any layer (the mapping does not depend on it).
                sv_tag string  % tag column of the rows (Nx1).
                sv_log string  % log column of the rows (Nx1).
            end
            arguments (Output)
                lv_odefcn      % True for rows that make the handles of the parameter's owner stale (Nx1).
                lv_equilibrium % True for rows that make the equilibrium stale (Nx1).
            end
            lv_odefcn      = sv_tag == "Parameter(dynamics)";
            lv_equilibrium = matches(sv_tag, ["Parameter(dynamics)", "Parameter(powerflow)", "Topology", "Slack", "Initialize"]) ...
                           | (sv_tag == "Parameter(base)" & sv_log ~= "edit Hz");
        end
    end
    methods
        varargout = disp_tree(obj, sr_ignore)
        [out, sct_visited] = struct(obj, l_disp, s_header, sct_visited)

        function doc(obj)
        % Open the class reference page of the layer's class.
        %
        % Opens the GUILDA class reference (English page) of class(obj) in the browser, as
        % GUILDA.doc("class", class(obj)). doc with a class name (doc PowerNetwork) is
        % MATLAB's doc.
        %
        % <@Examples>
        % ```matlab
        % net.doc()             % page of the network class
        % net.a_Bus{1}.doc()    % page of the class of the first bus
        % doc(net)              % same as net.doc()
        % ```
            arguments (Input)
                obj (1,1) % Layer whose class page is opened.
            end
            GUILDA.doc("class", class(obj));
        end

        function tab = get.tab_editLog(obj)
            % rows of every layer of the subtree (children form a tree: no layer twice)
            rv_seq = zeros(0,1);    rv_time = zeros(0,1);
            sv_id  = strings(0,1);  sv_log  = strings(0,1);  sv_tag = strings(0,1);
            c_before = cell(0,1);   c_after = cell(0,1);
            a_stack = {obj};
            while ~isempty(a_stack)
                a = a_stack{end};
                a_stack(end) = [];
                n = a.n_editLog;
                if n > 0
                    rv_seq   = [rv_seq;   a.rv_editSeq(1:n)];   %#ok<AGROW>
                    rv_time  = [rv_time;  a.rv_editTime(1:n)];  %#ok<AGROW>
                    sv_id    = [sv_id;    a.sv_editID(1:n)];    %#ok<AGROW>
                    sv_log   = [sv_log;   a.sv_editLog(1:n)];   %#ok<AGROW>
                    sv_tag   = [sv_tag;   a.sv_editTag(1:n)];   %#ok<AGROW>
                    c_before = [c_before; a.c_editBefore(1:n)]; %#ok<AGROW>
                    c_after  = [c_after;  a.c_editAfter(1:n)];  %#ok<AGROW>
                end
                a_stack = [a_stack; reshape(a.children,[],1)]; %#ok<AGROW>
            end
            % edit order: time, then the sequence number for edits within one clock tick
            [~, i] = sortrows([rv_time, rv_seq]);
            timestamp = string(datetime(rv_time(i), 'ConvertFrom','datenum', 'Format','uuuu/MM/dd HH:mm:ss'));
            tab = table(timestamp, sv_id(i), sv_log(i), sv_tag(i), c_before(i), c_after(i), ...
                        'VariableNames', ["timestamp","ID","log","tag","before","after"]);
        end

        function set.sct_edit(obj, sct_edit)
            % A field cannot have a validator, and assigning a misspelled field would add a new one
            mustBeA(sct_edit.l_initialized, "logical");
            mustBeMember(sct_edit.s_odefcn, ["unset","editted","updated"]);
            assert(numel(fieldnames(sct_edit)) == 2, "GUILDA:LayerPackage:EditStateFields", "sct_edit has exactly two fields.");
            obj.sct_edit = sct_edit;
        end

        function set.s_tag(obj,s_newtag)
            % A tag that already exists among the siblings gets a number suffix
            s_newtag = string(s_newtag);
            if obj.l_managedTag && ~isempty(obj.parent)
                a_sameLayer = obj.parent.children;
                l_me  = tools.vcellfun(@(a) a==obj, a_sameLayer);
                sv_sameLayer = string( a_sameLayer(~l_me) );
                if any(sv_sameLayer==s_newtag)
                    id = 2;
                    s_modified = s_newtag+num2str(id,"%.3d");
                    while ismember(s_modified, sv_sameLayer)
                        id = id+1;
                        s_modified = s_newtag+num2str(id,"%.3d");
                    end
                    fprintf("Info : Tag changed due to overlaps detected")
                    disp(['[ "',char(s_newtag),'" >> "',char(s_modified),'"]'])
                    s_newtag = s_modified;
                end
            end
            s_oldtag = obj.s_tag;
            obj.s_tag = s_newtag;
            % The first assignment (constructor) is not a rename.
            if ~isempty(s_oldtag) && s_oldtag ~= s_newtag
                obj.log_edit("rename " + s_oldtag + " -> " + s_newtag, "Tag", s_oldtag, s_newtag);
            end
        end
    end
    methods(Hidden)
        out = attach_tag(obj,sm_name_list)

        function tab = table(obj)
        % Convert layer parameters into table format.
        %
        % Returns the parameter table associated with this layer object.
        %
        % <@Examples>
        % ```matlab
        % tab = table(obj);
        % ```
            arguments (Input)
                obj
            end
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
            arguments (Input)
                obj
            end
            arguments (Output)
                str % Tag string of the layer object.
            end
            str = obj.s_tag;
        end
    end
end