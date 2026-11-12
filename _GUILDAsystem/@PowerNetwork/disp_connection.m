function varargout = disp_connection(obj, opt)
% Display the signal connections of the network: each input and the signals that drive it.
%
% A command-line view of the connection map of `get_variable_map` (its 4th output,
% `tab_connection`). The inputs are grouped by their owner in the order of the model:
% each bus, its components and their local controllers (depth first), then the global
% controllers. Under each owner, every input (Kind "u" or "uc" of the variable map) is
% listed first with its sources, then the components or controllers it holds. The tips
% of the tree lines (the heavy lines of `LayerPackage.disp_tree`) tell them apart:
% `┣━━<` / `┗━━<` for an input port, `┣━━o` / `┗━━o` for a held object. Each source is
% marked by the kind of the connection:
%
% - `local`: an output of a local controller into its parent
% - `global`: an output of a global controller into a unit or its local controllers
% - `observe`: an output or a state of a component read by a controller
% - `equilibrium`: the input keeps its equilibrium value
%
% A source is shown as "output <name> of <tag>" (an output y or yc) or "state <name> of
% <tag>" (a state x). An input with one source is joined to it by `━━`; an input
% with several sources is their sum, forked by `━┳`, `┣` and `┗`. An input of a
% global controller is shown as "<name> (<unit tag>)", one per controlled unit. Owners
% without a shown input are left out, and so are the buses without one; a last line counts
% the connections that the option Kind hides. The bus voltages that controllers read
% directly are not connections of the map and are not shown.
%
% The option Owner restricts the view to the given buses, components or controllers
% (each with what it holds: a bus with its components and their controllers, a component
% with its controllers): an input is shown when its owner is one of them, or when one of
% its sources is (so a global controller shows the inputs it drives, and a component the
% controllers that read it). A shown input always lists all its sources of the shown kinds.
% Each tag is followed by a link to the documentation of its class.
%
% <@Examples>
% ```matlab
% net = network.Tutorial10bus();
% net.disp_connection()                                  % local, global and observe
% net.disp_connection(Kind="global")                     % only the global controllers
% net.disp_connection(Owner="B001SG1")                   % one generator with its controllers
% net.disp_connection(Owner="PowerNetworkAGC1", Kind=["global","observe"])
% s = net.disp_connection(Kind=["local","global","observe","equilibrium"]);   % as text
% ```
%
% See also PowerNetwork.get_variable_map, LayerPackage.disp_tree
%
% <@Group> Queries and display
    arguments (Input)
        obj
        opt.Kind (1,:) string {mustBeMember(opt.Kind, ["local","global","observe","equilibrium"])} = ["local","global","observe"] % Kinds of connection shown; "equilibrium" adds the inputs that keep their equilibrium.
        opt.Owner (1,:) string = strings(1,0)   % Tags of buses, components or controllers to show (with what they hold); empty shows all.
    end
    arguments (Output, Repeating)
        varargout % Connection text when one output is requested; displayed otherwise.
    end
    [tab, ~, ~, tab_connection] = obj.get_variable_map();

    % Owners in scope: each tag of Owner with what it holds
    sv_all = owner_tags(obj);
    if isempty(opt.Owner)
        sv_scope = sv_all;
    else
        lv_unknown = ~ismember(opt.Owner, sv_all);
        if any(lv_unknown)
            error(msg("GUILDA:PowerNetwork:DispConnectionOwner", ...
                      char(join(opt.Owner(lv_unknown), ", ")), char(obj.s_tag)))
        end
        sv_scope = scope_tags(obj, opt.Owner);
    end

    % Inputs shown: the owner or a source in scope; then only the connections of the shown kinds
    sv_owner = tab.Owner(tab_connection.TargetIndex);
    sv_src   = strings(height(tab_connection), 1);
    lv_src   = tab_connection.SourceIndex > 0;
    sv_src(lv_src) = tab.Owner(tab_connection.SourceIndex(lv_src));
    lv_in    = ismember(sv_owner, sv_scope) | ismember(sv_src, sv_scope);
    iv_input = unique(tab_connection.TargetIndex(lv_in));
    lv_input = ismember(tab_connection.TargetIndex, iv_input);
    lv_kind  = ismember(tab_connection.Kind, opt.Kind);
    ctx.tab  = tab;
    ctx.conn = tab_connection(lv_input & lv_kind, :);

    sv_lines = strings(0,1);
    for i = 1:numel(obj.a_Bus)
        sv_lines = [sv_lines; top_block(obj.a_Bus{i}, ctx)]; %#ok<AGROW>
    end
    for k = 1:numel(obj.a_GlobalController)
        sv_lines = [sv_lines; top_block(obj.a_GlobalController{k}, ctx)]; %#ok<AGROW>
    end
    if isempty(sv_lines)
        sv_lines = [""; " (no connections to show)"];
    end

    s_head = " Signal connections of " + obj.s_tag + " " + link(obj) + newline ...
           + " <: input port, o: held object; several sources are summed (━┳); Kind: " + join(opt.Kind, ", ") + newline ...
           + " Bus voltages that controllers read directly are not connections and are not listed." + newline;
    s_foot = "";
    sv_hidden = setdiff(["local","global","observe","equilibrium"], opt.Kind, "stable");
    iv_n = arrayfun(@(s) sum(lv_input & tab_connection.Kind == s), sv_hidden);
    if any(iv_n > 0)
        sv_n = string(iv_n(iv_n > 0)) + " " + sv_hidden(iv_n > 0);
        s_foot = newline + " Not shown (option Kind): " + join(sv_n, ", ") + " connections" + newline;
    end
    text = newline + s_head + join(sv_lines, newline) + newline + s_foot;

    switch nargout
        case 0; disp(text)
        case 1; varargout{1} = text;
    end
end


function sv_lines = top_block(owner, ctx)
    % A bus or a global controller: its tag and its content, or nothing when it is empty
    sv_body = block(owner, ctx);
    if isempty(sv_body)
        sv_lines = strings(0,1);
    else
        sv_lines = [""; " " + owner.s_tag + " " + link(owner); sv_body];
    end
end

function sv_lines = block(owner, ctx)
    % Content of owner, at column 0: its inputs, then its components or local controllers
    c_item = input_items(owner, ctx);
    for k = 1:numel(c_item)
        c_item{k}.l_owner = false;
    end
    for k = 1:numel(children(owner))
        child = children(owner);
        child = child{k};
        sv_sub = block(child, ctx);
        if ~isempty(sv_sub)
            c_item{end+1} = struct("first", child.s_tag + " " + link(child), "more", sv_sub, "l_owner", true); %#ok<AGROW>
        end
    end
    sv_lines = strings(0,1);
    n_item = numel(c_item);
    for k = 1:n_item
        l_last = k == n_item;
        % heavy lines as in disp_tree; the tip is o for a held object, < for an input port (ASCII)
        if c_item{k}.l_owner
            sv_tip = ["   ┣━━o ", "   ┗━━o "];  sv_next = ["   ┃  ", "      "];
        else
            sv_tip = ["   ┣━━< ", "   ┗━━< "];  sv_next = ["   ┃    ", "        "];
        end
        s_branch = sv_tip(1 + l_last);
        s_next   = sv_next(1 + l_last);
        sv_lines = [sv_lines; s_branch + c_item{k}.first; s_next + c_item{k}.more]; %#ok<AGROW>
    end
end

function c_item = input_items(owner, ctx)
    % One item per shown input of owner: "name ━━ source  [kind]", the names and the
    % sources aligned within the owner
    tab  = ctx.tab;
    conn = ctx.conn;
    iv_row = find(ismember(tab.Kind, ["u","uc"]) & tab.Owner == string(owner.s_tag));
    sv_name = tab.Name(iv_row);
    if isa(owner, "GlobalController") && ~isempty(iv_row)
        % one set of inputs per controlled unit, unit by unit
        n_u = numel(owner.sv_u);
        sv_unit = string(cellfun(@(c) c.s_tag, owner.controlledUnits, "UniformOutput", false));
        sv_name = sv_name + " (" + reshape(sv_unit(ceil((1:numel(iv_row))' / n_u)), [], 1) + ")";
    end
    c_src = cell(numel(iv_row), 1);
    c_kind = cell(numel(iv_row), 1);
    for k = 1:numel(iv_row)
        conn_k = conn(conn.TargetIndex == iv_row(k), :);
        c_src{k} = arrayfun(@(i) source_text(tab, i), conn_k.SourceIndex);
        c_kind{k} = conn_k.Kind;
    end
    lv_show = ~cellfun(@isempty, c_src);
    sv_name = sv_name(lv_show);
    c_src = c_src(lv_show);
    c_kind = c_kind(lv_show);
    c_item = cell(1, numel(sv_name));
    if isempty(sv_name)
        return
    end
    n_name = max(strlength(sv_name));
    n_src  = max(cellfun(@(s) max(strlength(s)), c_src));
    for k = 1:numel(sv_name)
        sv_line = pad(c_src{k}, n_src) + "  [" + c_kind{k} + "]";
        n = numel(sv_line);
        if n == 1
            s_first = pad(sv_name(k), n_name) + " ━━ " + sv_line(1);
            sv_more = strings(0,1);
        else
            s_first = pad(sv_name(k), n_name) + " ━┳ " + sv_line(1);
            sv_mark = [repmat(" ┣ ", n-2, 1); " ┗ "];
            sv_more = string(blanks(n_name + 1)) + sv_mark + sv_line(2:end);
        end
        c_item{k} = struct("first", s_first, "more", sv_more);
    end
end

function s = source_text(tab, i)
    % "output <name> of <owner>", "state <name> of <owner>", or "equilibrium"
    if i == 0
        s = "equilibrium";
        return
    end
    switch tab.Kind(i)
        case {"y","yc"}; s_word = "output";
        case "x";        s_word = "state";
        otherwise;       s_word = tab.Kind(i);
    end
    s = s_word + " " + tab.Name(i) + " of " + tab.Owner(i);
end

function c = children(owner)
    % Owners held by owner, in the order of the variable map
    if isa(owner, "Bus")
        c = owner.a_Component;
    elseif isa(owner, "Component") || isa(owner, "LocalController")
        c = owner.a_LocalController;
    else
        c = cell(0,1);
    end
end

function sv = owner_tags(net)
    % Tags of every bus, component and controller of net
    sv = strings(0,1);
    for i = 1:numel(net.a_Bus)
        sv = [sv; subtree_tags(net.a_Bus{i})]; %#ok<AGROW>
    end
    for k = 1:numel(net.a_GlobalController)
        sv(end+1,1) = string(net.a_GlobalController{k}.s_tag); %#ok<AGROW>
    end
end

function sv = scope_tags(net, sv_owner)
    % Tags of the owners in sv_owner and of what they hold
    sv = strings(0,1);
    c_top = [net.a_Bus; net.a_GlobalController];
    for i = 1:numel(c_top)
        sv = [sv; find_scope(c_top{i}, sv_owner, false)]; %#ok<AGROW>
    end
end

function sv = find_scope(owner, sv_owner, l_in)
    % Tags under owner that are in scope (l_in: an ancestor is in sv_owner)
    l_in = l_in || any(string(owner.s_tag) == sv_owner);
    sv = strings(0,1);
    if l_in
        sv = string(owner.s_tag);
    end
    c = children(owner);
    for k = 1:numel(c)
        sv = [sv; find_scope(c{k}, sv_owner, l_in)]; %#ok<AGROW>
    end
end

function sv = subtree_tags(owner)
    % Tags of owner and of what it holds
    sv = string(owner.s_tag);
    c = children(owner);
    for k = 1:numel(c)
        sv = [sv; subtree_tags(c{k})]; %#ok<AGROW>
    end
end

function clsLink = link(cls)
    clsName = class(cls);
    clsLink = string(['<a href="matlab:doc(''',clsName,''');">@',clsName,'</a>']);
end
