classdef LayerPackage < handle
% Abstract base class for layer hierarchy management in GUILDA.
%
% It centralizes parent/children relationships, tag handling, and what is out of date:
% each layer keeps, per stale tag, the reasons it is stale; only PowerNetwork.initialize
% brings the layers up to date, and the analyses check them. The network, buses,
% branches, components, controllers (through PowerSystemModel), the scenarios and the
% Parameter containers derive from it. `gui` shows any layer (DrawerModelGUI) with the
% pages of `gui_content`.
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
%   ("<tag of the edited layer>: <log>", "<container tag>/<owner tag>: <log>" for a
%   parameter) to its own fields for the edits that make them stale.
% - Each analysis reads the stale tags it needs (the network, and the components and
%   controllers it uses) and stops with its own error (e.g. GUILDA:PowerNetwork:SimulateStale),
%   naming up to three different messages; it rebuilds nothing.
% - `sct_stale` has public GetAccess (Hidden) because the DebugScript tests, which are
%   scripts, read it.
%
% Tags: `s_tag` identifies the layer within the layer structure. A tag must be a valid
% MATLAB variable name (isvarname: a letter first, then letters, digits and underscores, at
% most namelengthmax characters, not a keyword), because tags name OPF constraints and
% struct fields; any other tag stops with GUILDA:LayerPackage:InvalidTag. A tag that
% already exists among the siblings is renamed with a number suffix (checked again). A
% rename is an edit with the tag "Tag", which makes nothing stale. Tags are permanent
% IDs, so the tags of existing child layers do not follow: after renaming bus B002 to BX,
% its component B002SG1 keeps its tag and a component added later is BXSG1.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.disp_tree();            % hierarchy of the layers below the network
% net.a_Bus{1}.doc();         % class reference page of the first bus
% net.a_Bus{1}.tab_parameter.powerflow.V = 1.02;
% net.sct_stale               % powerflow: "powerflow/B001: edit V: 1.06 -> 1.02"
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
        s_tag                                             % User-defined tag of the layer: a valid variable name (isvarname), unique among its siblings (see the class help). <@Type> string
    end

    methods(Access=protected)
        log_edit(obj, log, tag)
        handle_edit(obj, a_layer, tag, log)
        sct_page = gui_content(obj)
    end
    methods
        varargout = disp_tree(obj, sr_ignore)
        doc(obj)
        h = gui(obj, h_container)

        function set.s_tag(obj,s_newtag)
            % A tag must be a valid MATLAB variable name (OPF constraint names, struct fields).
            % A tag that already exists among the siblings gets a number suffix
            s_newtag = string(s_newtag);
            if ~isscalar(s_newtag) || ismissing(s_newtag) || ~isvarname(char(s_newtag))
                error(msg("GUILDA:LayerPackage:InvalidTag", char(join(string(s_newtag), ", ")), namelengthmax))
            end
            if ~isempty(obj.parent)
                a_sameLayer = obj.parent.children;
                l_me  = tools.vcellfun(@(a) a==obj, a_sameLayer);
                % A sibling without a tag yet (still being loaded from a MAT file) is
                % skipped: string() of it fails, and load drops the tag silently.
                c_tag = cellfun(@(a) a.s_tag, a_sameLayer(~l_me), "UniformOutput", false);
                sv_sameLayer = string( c_tag(~cellfun(@isempty, c_tag)) );
                if any(sv_sameLayer==s_newtag)
                    id = 2;
                    s_modified = s_newtag+num2str(id,"%.3d");
                    while ismember(s_modified, sv_sameLayer)
                        id = id+1;
                        s_modified = s_newtag+num2str(id,"%.3d");
                    end
                    if ~isvarname(char(s_modified))
                        error(msg("GUILDA:LayerPackage:InvalidTag", char(s_modified), namelengthmax))
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
