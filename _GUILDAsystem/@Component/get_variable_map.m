function tab = get_variable_map(obj)
% <@Desc>
% Variable map of the component: the rows of net.get_variable_map() that belong to it,
% in the same relative order. This order defines the Point vector of
% comp.get_sys(Point=...):
%   1. states x of the component, then of its local controllers (depth first: an AVR,
%      then the PSS attached under it)
%   2. Vre, Vim of its bus
%   3. inputs u of the component
% The columns are those of PowerNetwork.get_variable_map; Index counts from 1 here.
% <@Role> Static Analysis
% <@Summary> Variable map (order of the Point vector) of the component.
% <@Signatures>
% [
%   "tab = comp.get_variable_map()"
% ]
% <@Returns>
% [
%   {"Name": "tab", "Type": "table", "Description": "One row per variable: Index, Kind (\"x\" | \"Vre\" | \"Vim\" | \"u\"), Owner, Name, Label, Bus."}
% ]
% <@Examples>
% [
%   "```matlab\ntab = net.a_Bus{1}.a_Component{1}.get_variable_map();\ntab(tab.Kind == \"x\", :)\n```"
% ]
    str_bus = "";
    sv_V    = strings(2,1);
    if ~isempty(obj.a_Bus)
        str_bus = string(obj.a_Bus.str_tag);
        sv_V    = label(obj.a_Bus, ["Vre";"Vim"]);
    end

    a_obj = [{obj}; all_controllers(obj)];
    c_x   = cell(numel(a_obj),1);
    for k = 1:numel(a_obj)
        c_x{k} = rows(a_obj{k}, "x", a_obj{k}.sv_x, str_bus);
    end
    tab_V = table(["Vre";"Vim"], repmat(str_bus,2,1), ["Vre";"Vim"], sv_V, repmat(str_bus,2,1), ...
                  'VariableNames', ["Kind","Owner","Name","Label","Bus"]);
    tab_u = rows(obj, "u", obj.sv_u, str_bus);

    tab = [vertcat(c_x{:}); tab_V; tab_u];
    tab = [table((1:height(tab))', 'VariableNames', "Index"), tab];
end


function tab = rows(owner, str_kind, sv_name, str_bus)
    sv_name = reshape(string(sv_name), [], 1);
    n = numel(sv_name);
    tab = table(repmat(str_kind,n,1), repmat(string(owner.str_tag),n,1), sv_name, ...
                label(owner, sv_name), repmat(str_bus,n,1), ...
                'VariableNames', ["Kind","Owner","Name","Label","Bus"]);
end

function sv = label(owner, sv_name)
    % Tagged name: the state, input or port name used by get_sys
    if isempty(sv_name)
        sv = strings(0,1);
    else
        sv = reshape(string(owner.attach_tag(sv_name)), [], 1);
    end
end

function list = all_controllers(parent)
    % Same order as get_sys: depth first
    list = cell(0,1);
    for k = 1:numel(parent.a_LocalController)
        con  = parent.a_LocalController{k};
        list = [list; {con}; all_controllers(con)]; %#ok<AGROW>
    end
end
