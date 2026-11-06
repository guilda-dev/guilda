classdef LayerPackage < handle
% Abstract base class for layer hierarchy management in GUILDA.
%
% It centralizes parent/children relationships, tag handling, and what is out of date:
% each layer keeps, per stale tag, the reasons it is stale; only PowerNetwork.initialize
% brings the layers up to date, and the analyses check them. The network, buses,
% branches, components, controllers (through PowerSystemModel) and Parameter containers
% derive from it.
%
% Stale state:
%
% - `sct_stale` holds one field per stale tag of the class, each a string column of
%   messages (why that part is out of date); an empty column means up to date. The
%   constructor of each class creates its own fields with the message "initialize has
%   not been run": PowerNetwork `powerflow` and `odefcn` (the network frequency);
%   Component, LocalController and GlobalController `equilibrium` and `odefcn`; Bus and
%   Branch have none. Each class appends to and clears only its own fields.
% - An edit calls `log_edit(log, tag)` on the edited layer (the owner for a Parameter
%   container), which calls the hook `handle_edit` with that layer on every layer from
%   there up to the top. The default does nothing; each class appends the message
%   ("<tags of the edited layer>: <log>") to its own fields for the edits that make them
%   stale.
% - Each analysis reads the stale tags it needs (the network, and the components and
%   controllers it uses) and stops with its own error (e.g. GUILDA:SolverODE:Stale),
%   naming up to three different messages; it rebuilds nothing.
% - `sct_stale` has public GetAccess (Hidden) because the DebugScript tests, which are
%   scripts, read it.
%
% Tags: `s_tag` identifies the layer within the layer structure; a tag that already exists
% among the siblings is renamed with a number suffix. A rename is an edit with the tag
% "Tag", which makes nothing stale. Tags are permanent IDs, so the tags of existing
% child layers do not follow: after renaming bus B002 to BX, its component SG1B002 keeps
% its tag and a component added later is SG2BX.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.disp_tree();            % hierarchy of the layers below the network
% net.a_Bus{1}.doc();         % class reference page of the first bus
% net.a_Bus{1}.tab_parameter.powerflow.V = 1.02;
% net.sct_stale               % powerflow: "powerflow/B001/IEEE14bus: edit V: 1.06 -> 1.02"
% net.initialize();           % brings every layer up to date
% ```
%
% See also PowerSystemModel, Parameter

    %% Abstract
    properties(Abstract, Dependent) % Parameter
        tab_parameter                                     % Parameter table of the layer (PowerSystemModel: the a_Parameter tables side by side). <@Type> table
    end

    %% Layer Structure
    properties(Abstract, Dependent, Access=protected) % Layer structure
        parent                                            % Parent layer in the hierarchy. <@Type> LayerPackage
        children                                          % Child layers in the hierarchy. <@Type> LayerPackage cell array (Nx1)
    end
    %% Stale state
    properties(SetAccess=protected, Hidden) % Stale state
        sct_stale (1,1) struct = struct()                 % Messages per stale tag of the class (string column each; empty: up to date). See the class help.
    end
    properties(Constant, Hidden) % Stale state
        s_notInitialized = "initialize has not been run"  % Initial message of every stale tag.
    end
    
    %% Tag
    properties % Tag
        s_tag                                             % User-defined tag of the layer, unique among its siblings (see the class help). <@Type> string
    end

    methods(Access=protected)
        log_edit(obj, log, tag)
        handle_edit(obj, a_layer, tag, log)
    end
    methods(Access=private)
        out = get_tag(obj, s_split)
    end
    methods
        varargout = disp_tree(obj, sr_ignore)
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
                obj.log_edit("rename " + s_oldtag + " -> " + s_newtag, "Tag");
            end
        end
    end
    methods(Hidden)
        [out, sct_visited] = struct(obj, l_disp, s_header, sct_visited)
        out = attach_tag(obj,sm_name_list)
        tab = table(obj)
        str = string(obj)
    end
end
