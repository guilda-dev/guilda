function G = plot_connection(obj, opt)
% Draw the signal connections of the network as a block diagram.
%
% The picture of `disp_connection`: the same connection map of `get_variable_map` (its 4th
% output, `tab_connection`) with the same options, drawn by a GraphConnection. The blocks
% are the buses, components, local controllers and global controllers, in layers from
% left to right: global controllers, local controllers (a controller held by another one
% to its left), components and buses. The arrows go from the block that gives a signal
% to the block that takes it and are labeled with the names of the inputs they drive; an
% input whose source has another name is labeled "<source name>→<input name>". The signals
% between the same two blocks of one kind share one arrow. The kind of the connection sets
% the color and the line style:
%
% - `local`: an output of a local controller into its parent (blue, solid)
% - `global`: an output of a global controller into a unit or its local controllers (orange, solid)
% - `observe`: an output or a state of a component read by a controller (green, dashed)
% - `equilibrium`: the input keeps its equilibrium value (gray, dotted, from a short stub)
%
% The blocks drawn are the ends of the connections shown, with the blocks that hold them
% (a controller with its component and its bus). The option Owner restricts the view as
% in disp_connection: a connection is shown when the owner of its input, or of one of the
% sources of that input, is one of the given buses, components or controllers or is held
% by one of them. The bus voltages that controllers read directly are not connections of
% the map and are not drawn.
%
% <@Examples>
% ```matlab
% net = network.Tutorial10bus();
% G = net.plot_connection();                              % local, global and observe
% G = net.plot_connection(Kind="global");                 % only the global controllers
% G = net.plot_connection(Owner="B001SG1");               % one generator with its controllers
% G.set_style("B001SG1CA1->B001SG1", Color="r", LineWidth=2);
% G.tab_element                                           % blocks and arrows
% ```
%
% See also PowerNetwork.disp_connection, PowerNetwork.get_variable_map, GraphConnection
%
% <@Group> Queries and display
    arguments (Input)
        obj
        opt.Kind (1,:) string {mustBeMember(opt.Kind, ["local","global","observe","equilibrium"])} = ["local","global","observe"]  % Kinds of connection drawn; "equilibrium" adds the inputs that keep their equilibrium.
        opt.Owner (1,:) string = strings(1,0)  % Tags of buses, components or controllers to show (with what they hold); empty shows all.
        opt.Parent = []                        % Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure.
    end
    arguments (Output)
        G  % The diagram: a GraphConnection object.
    end
    [tab, ~, ~, tab_connection] = obj.get_variable_map();

    % Every owner of the model in order: tag, kind, holder, class
    sct_own = struct("sv_tag", strings(0,1), "sv_kind", strings(0,1), "sv_parent", strings(0,1), "sv_class", strings(0,1));
    for i = 1:numel(obj.a_Bus)
        sct_own = add_owner(sct_own, obj.a_Bus{i}, "");
    end
    for k = 1:numel(obj.a_GlobalController)
        sct_own = add_owner(sct_own, obj.a_GlobalController{k}, "");
    end

    % Owners in scope: each tag of Owner with what it holds
    if isempty(opt.Owner)
        sv_scope = sct_own.sv_tag;
    else
        lv_unknown = ~ismember(opt.Owner, sct_own.sv_tag);
        if any(lv_unknown)
            error(msg("GUILDA:PowerNetwork:PlotConnectionOwner", ...
                      char(join(opt.Owner(lv_unknown), ", ")), char(obj.s_tag)))
        end
        sv_scope = opt.Owner(:);
        n_scope = 0;
        while numel(sv_scope) > n_scope                         % add the held owners until none is new
            n_scope = numel(sv_scope);
            sv_scope = unique([sv_scope; sct_own.sv_tag(ismember(sct_own.sv_parent, sv_scope))], "stable");
        end
    end

    % Connections shown: an input whose owner or one of whose sources is in scope; then the kinds
    sv_tgt = tab.Owner(tab_connection.TargetIndex);
    sv_src = strings(height(tab_connection), 1);
    lv_src = tab_connection.SourceIndex > 0;
    sv_src(lv_src) = tab.Owner(tab_connection.SourceIndex(lv_src));
    lv_in  = ismember(sv_tgt, sv_scope) | ismember(sv_src, sv_scope);
    lv_input = ismember(tab_connection.TargetIndex, unique(tab_connection.TargetIndex(lv_in)));
    iv_show = find(lv_input & ismember(tab_connection.Kind, opt.Kind));

    % One arrow per source block, target block and kind; its label lists the inputs
    sv_name = tab.Name(tab_connection.TargetIndex(iv_show));
    sv_from = strings(numel(iv_show), 1);
    lv_from = lv_src(iv_show);
    sv_from(lv_from) = tab.Name(tab_connection.SourceIndex(iv_show(lv_from)));
    lv_other = lv_from & sv_from ~= sv_name;
    sv_name(lv_other) = sv_from(lv_other) + "→" + sv_name(lv_other);
    sv_key = sv_src(iv_show) + newline + sv_tgt(iv_show) + newline + tab_connection.Kind(iv_show);
    [sv_unique, iv_first] = unique(sv_key, "stable");
    n_a = numel(sv_unique);
    sv_label = strings(n_a, 1);
    for k = 1:n_a
        sv_label(k) = join(unique(sv_name(sv_key == sv_unique(k)), "stable"), ", ");
    end
    iv_arrow = iv_show(iv_first);

    % Blocks: the ends of the arrows and their holders, in the order of the model
    sv_end = unique([sv_src(iv_arrow); sv_tgt(iv_arrow)]);
    sv_end = sv_end(sv_end ~= "");
    n_end = 0;
    while numel(sv_end) > n_end
        n_end = numel(sv_end);
        sv_up = sct_own.sv_parent(ismember(sct_own.sv_tag, sv_end));
        sv_end = unique([sv_end; sv_up(sv_up ~= "")]);
    end
    lv_block = ismember(sct_own.sv_tag, sv_end);

    sct = struct();
    sct.sv_blockTag    = sct_own.sv_tag(lv_block);
    sct.sv_blockKind   = sct_own.sv_kind(lv_block);
    sct.sv_blockParent = sct_own.sv_parent(lv_block);
    sct.sv_blockClass  = sct_own.sv_class(lv_block);
    sct.sv_arrowSource = sv_src(iv_arrow);
    sct.sv_arrowTarget = sv_tgt(iv_arrow);
    sct.sv_arrowKind   = tab_connection.Kind(iv_arrow);
    sct.sv_arrowLabel  = sv_label;
    sct.s_title = "Signal connections of " + obj.s_tag + " (" + join(opt.Kind, ", ") + ")";
    if n_a == 0
        sct.s_title = sct.s_title + ": no connections to show";
    end
    G = GraphConnection(sct, Parent=opt.Parent);
end


function sct_own = add_owner(sct_own, owner, s_parent)
% Append owner and, depth first, the components or local controllers it holds.
    arguments (Input)
        sct_own (1,1) struct      % Owners so far.
        owner                     % Bus, Component, LocalController or GlobalController.
        s_parent (1,1) string     % Tag of the holder ("" for a bus or a global controller).
    end
    arguments (Output)
        sct_own (1,1) struct      % Owners with owner and its held owners.
    end
    if isa(owner, "Bus")
        s_kind = "bus";
        c_child = owner.a_Component;
    elseif isa(owner, "Component")
        s_kind = "component";
        c_child = owner.a_LocalController;
    elseif isa(owner, "LocalController")
        s_kind = "localcontroller";
        c_child = owner.a_LocalController;
    else
        s_kind = "globalcontroller";
        c_child = {};
    end
    s_class = "";
    if s_kind ~= "bus"
        sv_part = split(string(class(owner)), ".");
        s_class = sv_part(end);
        if numel(sv_part) >= 2
            s_class = sv_part(end-1) + "." + s_class;
        end
    end
    sct_own.sv_tag(end+1, 1)    = string(owner.s_tag);
    sct_own.sv_kind(end+1, 1)   = s_kind;
    sct_own.sv_parent(end+1, 1) = s_parent;
    sct_own.sv_class(end+1, 1)  = s_class;
    for k = 1:numel(c_child)
        sct_own = add_owner(sct_own, c_child{k}, string(owner.s_tag));
    end
end
