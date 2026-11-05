function tab = get_variable_map(obj, s_form)
% Return the variable map of the component: the order of its Point vector.
%
% Variable map of the component: the rows of net.get_variable_map() that belong to it,
% in the same relative order. This order defines the Point vector of
% comp.get_sys(Point=...):
%   1. states x of the component, then of its local controllers (depth first: the AVR
%      or "local" controller, the PSS attached under the AVR, then the governor)
%   2. Vre, Vim of its bus
%   3. inputs u of the component
% The columns are those of PowerNetwork.get_variable_map; Index counts from 1 here.
% get_variable_map("rows") is the form used inside the map: see PowerNetwork.get_variable_map.
%
% <@Examples>
% ```matlab
% tab = net.a_Bus{1}.a_Component{1}.get_variable_map();
% tab(tab.Kind == "x", :)
% ```
%
% See also PowerNetwork.get_variable_map, Component.get_sys
%
% <@Group> Called by analyses
    arguments
        obj
        s_form (1,1) string {mustBeMember(s_form, ["table","rows"])} = "table" % "rows" (internal): return the rows without the table.
    end
    arguments (Output)
        tab   % One row per variable: Index, Kind ("x" | "Vre" | "Vim" | "u"), Owner, Name, Label, Bus.
    end
    s_bus   = "";
    sv_V    = strings(2,1);
    if ~isempty(obj.a_Bus)
        s_bus   = string(obj.a_Bus.s_tag);
        sv_V    = label(obj.a_Bus, ["Vre";"Vim"]);
    end

    a_obj = [{obj}; all_controllers(obj)];
    c_x   = cell(numel(a_obj),1);
    for k = 1:numel(a_obj)
        c_x{k} = rows(a_obj{k}, "x", a_obj{k}.sv_x, s_bus);
    end
    sm_V   = [["Vre";"Vim"], repmat(s_bus,2,1), ["Vre";"Vim"], sv_V, repmat(s_bus,2,1)];
    c_rows = {vertcat(c_x{:}); sm_V; rows(obj, "u", obj.sv_u, s_bus)};
    if s_form == "rows"
        tab = c_rows;
        return
    end

    sm  = vertcat(c_rows{:});
    tab = table((1:size(sm,1))', sm(:,1), sm(:,2), sm(:,3), sm(:,4), sm(:,5), ...
                'VariableNames', ["Index","Kind","Owner","Name","Label","Bus"]);
end


function sm = rows(owner, s_kind, sv_name, s_bus)
    % Columns Kind, Owner, Name, Label, Bus of the variables of owner
    sv_name = reshape(string(sv_name), [], 1);
    n = numel(sv_name);
    sm = [repmat(s_kind,n,1), repmat(string(owner.s_tag),n,1), sv_name, ...
          label(owner, sv_name), repmat(s_bus,n,1)];
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
