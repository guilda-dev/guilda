function sct_layout = get_layout(obj)
% Return the layout of the network diagrams: the graph parameters of all elements by tag.
%
% The struct has one table per kind of element, one row per element in the order of
% a_Bus, a_Branch and the components bus by bus, with the tag as the column Tag:
%
% - tab_bus: Tag, X, Y, Shape, Length, MarkerSize, Color
% - tab_branch: Tag, From, To (tags of the end buses, read only), Path, FromOffset,
%   ToOffset, Style
% - tab_component: Tag (full tag), Bus (tag of the bus, read only), DX, DY, Shape, Path,
%   Offset, MarkerSize, Color
%
% The network is not changed. Edit the tables and give them to net.set_layout to write
% them back; writetable writes each table as a CSV file as it is.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% L = net.get_layout();
% L.tab_bus(L.tab_bus.Shape == "hbar", ["Tag", "X", "Length"])
% L.tab_bus.Length(L.tab_bus.Shape == "hbar") = 0.12;
% net.set_layout(L);
% ```
%
% See also PowerNetwork.set_layout, PowerNetwork.plot_diagram
%
% <@Group> Queries and display
    arguments (Input)
        obj
    end
    arguments (Output)
        sct_layout (1,1) struct  % Layout: fields tab_bus, tab_branch, tab_component (tables with the column Tag).
    end
    c_comp = cellfun(@(b) b.a_Component(:), obj.a_Bus(:), 'UniformOutput', false);
    a_comp = vertcat(cell(0, 1), c_comp{:});
    get_graph = @(e) e.a_Parameter{cellfun(@(p) p.s_tag == "graph", e.a_Parameter)}.tab_parameter;
    get_tags  = @(a_e, f) reshape(string(cellfun(@(e) char(f(e)), a_e, 'UniformOutput', false)), [], 1);

    % Graph columns of a network without elements of a kind (as the defaults of add_*)
    c_none = {table(nan(0,1), nan(0,1), strings(0,1), nan(0,1), nan(0,1), strings(0,1), ...
                  'VariableNames', ["X", "Y", "Shape", "Length", "MarkerSize", "Color"]), ...
              table(strings(0,1), nan(0,1), nan(0,1), strings(0,1), ...
                  'VariableNames', ["Path", "FromOffset", "ToOffset", "Style"]), ...
              table(nan(0,1), nan(0,1), strings(0,1), strings(0,1), nan(0,1), nan(0,1), strings(0,1), ...
                  'VariableNames', ["DX", "DY", "Shape", "Path", "Offset", "MarkerSize", "Color"])};
    c_elem = {obj.a_Bus(:), obj.a_Branch(:), a_comp};
    c_tab  = cell(1, 3);
    for k = 1:3
        a_e = c_elem{k};
        Tag = get_tags(a_e, @(e) e.s_tag);
        if isempty(a_e)
            tab_g = c_none{k};
        else
            c_g   = cellfun(get_graph, a_e, 'UniformOutput', false);
            tab_g = vertcat(c_g{:});
        end
        c_tab{k} = [table(Tag), tab_g];
    end
    % End buses (read only)
    From = get_tags(obj.a_Branch(:), @(e) e.a_Bus{1}.s_tag);
    To   = get_tags(obj.a_Branch(:), @(e) e.a_Bus{2}.s_tag);
    Bus  = get_tags(a_comp, @(e) e.a_Bus.s_tag);
    sct_layout = struct("tab_bus", c_tab{1}, ...
        "tab_branch",    [c_tab{2}(:, "Tag"), table(From, To), c_tab{2}(:, 2:end)], ...
        "tab_component", [c_tab{3}(:, "Tag"), table(Bus),      c_tab{3}(:, 2:end)]);
end
