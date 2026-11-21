function set_parameter(obj, Group, tab)
% Write one parameter group of many elements from a table: one row per element.
%
% tab has the form of net.get_parameter(Group): the row names are the tags of the elements
% (a global controller with one row per unit: "<controller tag>/<unit tag>"), the columns
% parameters of the group. Any part can be given: some of the rows and some of the
% columns; what is not given stays. Each row is written into tab_parameter.(Group) of its
% element, as writing that table directly does: each changed value is an edit of the
% element (e.g. "powerflow/B005LRX1: edit P: -1.25 -> -1.875"), which makes the power flow
% or the equilibrium stale as usual, and an unchanged value is no edit.
%
% Every row is checked before any write, and nothing is written when one is wrong: a
% table without row names stops with GUILDA:PowerNetwork:ParameterNoRowNames; a row name
% that is not a tag of an element with the group, with GUILDA:PowerNetwork:ParameterUnknownRow;
% a column that the element does not have, with GUILDA:PowerNetwork:ParameterUnknownColumn
% (except in a table of mixed models from get_parameter: its Key column and, in a row, the
% filled value of a parameter the element does not have, NaN, <missing> or false, are
% skipped);
% a column of another class than the stored one (e.g. a string for a number), with
% GUILDA:PowerNetwork:ParameterClassMismatch; a value that the check of the group rejects
% (the graph parameters) stops with the error of that check.
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% tab = net.get_parameter("powerflow", Key="load-impedance");
% tab.P = 1.5*tab.P;  tab.Q = 1.5*tab.Q;                 % all loads x1.5
% net.set_parameter("powerflow", tab);
%
% tab = net.get_parameter("OPF", Key="gen-1axis");
% tab{:, ["HP", "fP"]} = [0.02 2; 0.03 1.5; 0.025 1.8];  % quadratic and linear costs
% net.set_parameter("OPF", tab);
%
% tab = net.get_parameter("dynamics", Key="gen-1axis");
% net.set_parameter("dynamics", tab("B002SG1", "D"));   % one value: D of B002SG1 (unchanged)
% ```
%
% See also PowerNetwork.get_parameter, PowerNetwork.get_element, Parameter
%
% <@Group> Model building
    arguments (Input)
        obj
        Group (1,1) string  % Parameter group, e.g. "powerflow", "dynamics", "operation", "OPF", "graph".
        tab   table         % Values: row names = tags of the elements, columns = parameters of the group.
    end
    sv_row = string(tab.Properties.RowNames);
    if isempty(sv_row) && height(tab) > 0
        error(msg("GUILDA:PowerNetwork:ParameterNoRowNames", char(Group)))
    end
    [c_elem, sv_kind] = element_list(obj);
    c_elem = c_elem(sv_kind ~= "scenario");
    sv_tag = string(cellfun(@(e) e.s_tag, c_elem, "UniformOutput", false));
    sv_col = string(tab.Properties.VariableNames);

    % New tables of every element of the rows, all checked before any write
    c_para = cell(0, 1);
    c_new  = cell(0, 1);
    for i_row = 1:height(tab)
        s_row = sv_row(i_row);
        s_tag = extractBefore(s_row + "/", "/");     % "<controller tag>/<unit tag>" for a unit row
        i_e   = find(sv_tag == s_tag);
        a_p   = {};
        if isscalar(i_e)
            a_p = c_elem{i_e}.a_Parameter(cellfun(@(p) p.s_tag == Group, c_elem{i_e}.a_Parameter));
        end
        if isempty(a_p)
            error(msg("GUILDA:PowerNetwork:ParameterUnknownRow", char(s_row), char(Group), char(obj.s_tag)))
        end
        para  = a_p{1};
        i_old = find(cellfun(@(p) p == para, c_para), 1);
        if isempty(i_old)
            tab_g = para.tab_parameter;
        else
            tab_g = c_new{i_old};
        end
        % the row of the element: its only row, or the row of the unit
        if s_row == s_tag && height(tab_g) == 1
            i_g = 1;
        else
            i_g = find(string(tab_g.Properties.RowNames) == extractAfter(s_row, "/"));
        end
        if ~isscalar(i_g)
            error(msg("GUILDA:PowerNetwork:ParameterUnknownRow", char(s_row), char(Group), char(obj.s_tag)))
        end
        % the columns of a table of mixed models that this element does not have: the Key
        % column and the filled values (NaN, <missing>, false) are skipped
        sv_known = string(tab_g.Properties.VariableNames);
        lv_skip  = arrayfun(@(s) ~ismember(s, sv_known) && (s == "Key" || ...
            (islogical(tab.(s)) && ~any(tab.(s)(i_row, :))) || (~islogical(tab.(s)) && all(ismissing(tab.(s)(i_row, :))))), sv_col);
        sv_bad   = setdiff(sv_col(~lv_skip), sv_known, "stable");
        if ~isempty(sv_bad)
            error(msg("GUILDA:PowerNetwork:ParameterUnknownColumn", char(s_row), char(Group), ...
                char(strjoin(sv_bad, ", ")), char(strjoin(sv_known, ", "))))
        end
        for s_col = sv_col(~lv_skip)
            if ~strcmp(class(tab.(s_col)), class(tab_g.(s_col)))
                error(msg("GUILDA:PowerNetwork:ParameterClassMismatch", char(s_row), char(s_col), ...
                    class(tab_g.(s_col)), class(tab.(s_col))))
            end
            tab_g.(s_col)(i_g, :) = tab.(s_col)(i_row, :);
        end
        if ~isempty(para.f_validate)
            para.f_validate(tab_g, s_tag);
        end
        if isempty(i_old)
            c_para{end+1, 1} = para;                     %#ok<AGROW>
            c_new{end+1, 1}  = tab_g;                    %#ok<AGROW>
        else
            c_new{i_old} = tab_g;
        end
    end

    % Write: each changed column is an edit of its element
    for i = 1:numel(c_para)
        c_para{i}.tab_parameter = c_new{i};
    end
end
