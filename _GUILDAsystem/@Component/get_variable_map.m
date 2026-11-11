function [tab, tab_connection] = get_variable_map(obj, s_form)
% Return the variable map of the component and the connections inside it.
%
% Variable map of the component: the rows of net.get_variable_map() that belong to it,
% in the same relative order (see PowerNetwork.get_variable_map for the columns):
%   1. x: states of the component, then of its local controllers (depth first: the AVR or
%      "local" controller, the PSS attached under the AVR, then the governor)
%   2. Vre, Vim of its bus
%   3. u: inputs of the component
%   4. uc: inputs of its local controllers (depth first)
%   5. y: outputs of the component (signals)
%   6. yc: outputs of its local controllers (signals)
% The rows of the kinds x, Vre, Vim and u come first: they are the order of the Point
% vector of comp.get_sys(Point=...). Index counts from 1 here.
% tab_connection lists the connections inside the component: the outputs of the local
% controllers into the inputs of the same name of their parent ("local"), the outputs and
% states of the component into the inputs of the controllers that observe them
% ("observe"), and the equilibrium of an input without either ("equilibrium"). The
% connections of the global controllers are only in the map of the network.
% get_variable_map("rows") is the form used inside the map: see PowerNetwork.get_variable_map.
%
% <@Examples>
% ```matlab
% [tab, tab_connection] = net.a_Bus{1}.a_Component{1}.get_variable_map();
% tab(tab.Kind == "x", :)
% ```
%
% See also PowerNetwork.get_variable_map, Component.get_sys
%
% <@Group> Called by analyses
    arguments (Input)
        obj
        s_form (1,1) string {mustBeMember(s_form, ["table","rows"])} = "table" % "rows" (internal): return the rows without the tables.
    end
    arguments (Output)
        tab              % One row per variable or signal: Index, Kind, Role, Owner, Name, Label, Bus.
        tab_connection   % One row per connection: Index, Kind, Source, Target, SourceIndex, TargetIndex.
    end
    s_bus   = "";
    sv_V    = strings(2,1);
    if ~isempty(obj.a_Bus)
        s_bus   = string(obj.a_Bus.s_tag);
        sv_V    = label(obj.a_Bus, ["Vre";"Vim"]);
    end

    a_LC  = all_controllers(obj);
    a_obj = [{obj}; a_LC];
    c_x   = tools.cellfun(@(o) rows(o, "x", o.sv_x, label(o, o.sv_x), s_bus), a_obj);
    c_uc  = tools.cellfun(@(o) rows(o, "uc", o.sv_u, label(o, o.sv_u), s_bus), a_LC);
    c_yc  = tools.cellfun(@(o) rows(o, "yc", o.sv_y, label_y(o, o.sv_y), s_bus), a_LC);
    sm_V  = [["Vre";"Vim"], repmat(s_bus,2,1), ["Vre";"Vim"], sv_V, repmat(s_bus,2,1)];
    c_rows = {vertcat(strings(0,5), c_x{:}); sm_V; rows(obj, "u", obj.sv_u, label(obj, obj.sv_u), s_bus); ...
              vertcat(strings(0,5), c_uc{:}); rows(obj, "y", obj.sv_y, label_y(obj, obj.sv_y), s_bus); ...
              vertcat(strings(0,5), c_yc{:})};

    % Connections, in the order of the inputs they drive: the inputs of the component, then
    % those of each controller. A nested controller's output drives the input of its parent
    % of the same name; otherwise a controller input observes the component (an output
    % before a state of the same name, iv_obsY / iv_obsX), and any other input keeps its
    % equilibrium. Columns: Kind, kind and label of the source, kind and label of the target.
    c_conn = tools.cellfun(@(o) connections(o, obj), a_obj);
    sm_conn = vertcat(strings(0,5), c_conn{:});

    if s_form == "rows"
        tab = c_rows;
        tab_connection = sm_conn;
        return
    end
    [tab, tab_connection] = make_tables(vertcat(c_rows{:}), sm_conn);
end


function sm = connections(owner, comp)
    % Connections into the inputs of owner (the component or one of its controllers)
    sv_in = reshape(string(owner.sv_u), [], 1);
    l_comp = isa(owner, "Component");
    s_tgt = "uc";
    if l_comp
        s_tgt = "u";
    end
    sv_tgt = label(owner, sv_in);
    sm = strings(numel(sv_in), 5);
    a_sub = owner.a_LocalController;
    for k = 1:numel(sv_in)
        i_sub = find(cellfun(@(c) any(c.sv_y == sv_in(k)), a_sub), 1);
        if ~isempty(i_sub)
            sub = a_sub{i_sub};
            sm(k,:) = ["local", "yc", label_y(sub, sv_in(k)), s_tgt, sv_tgt(k)];
        elseif ~l_comp && owner.iv_obsY(k) > 0
            sm(k,:) = ["observe", "y", label_y(comp, comp.sv_y(owner.iv_obsY(k))), s_tgt, sv_tgt(k)];
        elseif ~l_comp && owner.iv_obsX(k) > 0
            sm(k,:) = ["observe", "x", label(comp, comp.sv_x(owner.iv_obsX(k))), s_tgt, sv_tgt(k)];
        else
            sm(k,:) = ["equilibrium", "", "", s_tgt, sv_tgt(k)];
        end
    end
end

function [tab, tab_connection] = make_tables(sm, sm_conn)
    % The tables from the rows; the connections point to the rows by Index
    n = size(sm,1);
    sv_role = repmat("variable", n, 1);
    sv_role(ismember(sm(:,1), ["y","yc"])) = "signal";
    tab = table((1:n)', sm(:,1), sv_role, sm(:,2), sm(:,3), sm(:,4), sm(:,5), ...
                'VariableNames', ["Index","Kind","Role","Owner","Name","Label","Bus"]);
    sv_key = sm(:,1) + "|" + sm(:,4);
    [~, iv_src] = ismember(sm_conn(:,2) + "|" + sm_conn(:,3), sv_key);
    [~, iv_tgt] = ismember(sm_conn(:,4) + "|" + sm_conn(:,5), sv_key);
    [iv_tgt, iv_ord] = sort(iv_tgt);
    sm_conn = sm_conn(iv_ord,:);
    m = size(sm_conn,1);
    tab_connection = table((1:m)', sm_conn(:,1), sm_conn(:,3), sm_conn(:,5), iv_src(iv_ord), iv_tgt, ...
                           'VariableNames', ["Index","Kind","Source","Target","SourceIndex","TargetIndex"]);
end

function sm = rows(owner, s_kind, sv_name, sv_label, s_bus)
    % Columns Kind, Owner, Name, Label, Bus of the variables or signals of owner
    sv_name = reshape(string(sv_name), [], 1);
    n = numel(sv_name);
    sm = [repmat(s_kind,n,1), repmat(string(owner.s_tag),n,1), sv_name, sv_label, repmat(s_bus,n,1)];
end

function sv = label(owner, sv_name)
    % Tagged name: the state, input or port name used by get_sys
    if isempty(sv_name)
        sv = strings(0,1);
    else
        sv = reshape(string(owner.attach_tag(reshape(string(sv_name), [], 1))), [], 1);
    end
end

function sv = label_y(owner, sv_name)
    % Tagged output name, as in get_sys: "Y_" + name when owner has a state of that name
    sv_name = reshape(string(sv_name), [], 1);
    lv = ismember(sv_name, owner.sv_x);
    sv_name(lv) = "Y_" + sv_name(lv);
    sv = label(owner, sv_name);
end

function list = all_controllers(parent)
    % Same order as get_sys: depth first
    list = cell(0,1);
    for k = 1:numel(parent.a_LocalController)
        con  = parent.a_LocalController{k};
        list = [list; {con}; all_controllers(con)]; %#ok<AGROW>
    end
end
