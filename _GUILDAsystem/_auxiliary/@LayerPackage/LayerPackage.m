classdef LayerPackage < handle
% Abstract base class for layer hierarchy management in GUILDA.
%
% It centralizes parent/children relationships, tag handling, and the edit log: each layer
% records its own edits with log_edit (the edits of a Parameter container on its owner)
% once it has been initialized, and disp_edit of a layer shows the edits of the layer and
% its subtree. The network, buses, branches, components, controllers (through
% PowerSystemModel) and Parameter containers derive from it.
%
% Edit log:
%
% - `disp_edit` shows the edits since the last initialize of the layer and of every layer
%   below it (children, recursively), in the order they were made: net.disp_edit() shows
%   every edit of the network, bus.disp_edit() only those of the bus, its components and
%   their controllers. Columns: timestamp ("uuuu/MM/dd HH:mm:ss"), ID (tags from the edited
%   layer up, joined by "/"; a parameter edit starts with its group, e.g.
%   "powerflow/SG1B005/B005/TestSystem"), log message, tag (kind of edit), states before
%   and after. With an output argument it returns the table instead of displaying it.
% - Each layer keeps its own rows in `sct_editLog` (one struct per edit, appended by
%   log_edit) once `l_initialized` is true. reset_edit clears the rows of the subtree and
%   sets the flag: true at the end of initialize, false when the layer is attached to a
%   new parent, so edits made elsewhere do not show in the new hierarchy.
% - After storing the row, log_edit calls `handle_edit` on every layer from the edited
%   layer (the owner of a Parameter container) up to the top, also before the first
%   initialize. The default does nothing; subclasses override it for their own rules.
%   collect_edit returns the rows of a subtree in edit order, for the subclasses that
%   check them.
% - `l_initialized` has public GetAccess (Hidden) because the DebugScript tests, which
%   are scripts, read it.
%
% Tags: `s_tag` identifies the layer within the layer structure; a tag that already exists
% among the siblings is renamed with a number suffix. A rename is recorded in the edit log
% (tag "Tag"). Tags are permanent IDs, so the tags of existing
% child layers do not follow: after renaming bus B002 to BX, its component SG1B002 keeps
% its tag and a component added later is SG2BX.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.disp_tree();            % hierarchy of the layers below the network
% net.a_Bus{1}.doc();         % class reference page of the first bus
% net.disp_edit()             % edits since the last net.initialize
% net.a_Bus{1}.disp_edit()    % only the edits of the first bus and the layers below it
% tab = net.disp_edit();      % the same rows as a table
% ```
%
% See also PowerSystemModel, Parameter

    %% Abstract
    properties(Abstract, Dependent) % Parameter
        tab_parameter  % Parameter table: the para_* tables side by side. <@Type> table
    end

    %% Layer Structure
    properties(Abstract, Dependent, Access=protected) % Layer structure
        parent  % Parent layer in the hierarchy. <@Type> LayerPackage
        children  % Child layers in the hierarchy. <@Type> LayerPackage cell array (Nx1)
    end
    %% Edit log
    properties(SetAccess=private, Hidden) % Edit log
        l_initialized (1,1) logical = false  % True once initialize has run with the layer in its hierarchy (reset_edit; see the class help).
    end
    properties(Access=private, Hidden) % Edit log storage
        sct_editLog = struct("i_seq",{}, "r_time",{}, "s_ID",{}, "s_log",{}, "s_tag",{}, "before",{}, "after",{})  % Own edits of the layer, one struct per edit (log_edit).
    end
    
    %% Tag
    properties % Tag
        s_tag  % User-defined tag of the layer, unique among its siblings (see the class help). <@Type> string
    end

    methods(Access=protected)
        log_edit(obj, log, tag, before, after)
        reset_edit(obj, l_initialized)
        sct_log = collect_edit(obj)
        handle_edit(obj, a_layer, tag, log)
    end
    methods(Access=private)
        out = get_tag(obj, s_split)
    end
    methods
        varargout = disp_tree(obj, sr_ignore)
        varargout = disp_edit(obj)
        [out, sct_visited] = struct(obj, l_disp, s_header, sct_visited)
        doc(obj)

        function set.s_tag(obj,s_newtag)
            % A tag that already exists among the siblings gets a number suffix
            s_newtag = string(s_newtag);
            if ~isempty(obj.parent)
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
        tab = table(obj)
        str = string(obj)
    end
end
