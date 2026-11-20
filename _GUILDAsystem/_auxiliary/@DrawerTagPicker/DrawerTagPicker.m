classdef DrawerTagPicker < auxiliary
% Searchable table picker of tags and model keys, with the element tables it shows.
%
% The picker shows one row per element in a uitable, with the columns that tell elements
% apart (the bus of a component, its position on the bus, its class), and a search box
% above it. The user only searches and chooses: the tables are built from the network when
% the picker opens, never in advance.
%
% - element_table(net, s_kind): one row per element of one kind, in a single pass over the
%   network (no struct(net, false), no copies). The columns by kind:
%
% | Kind | Columns |
% |---|---|
% | Bus | Tag, Index, Type ("slack", "PV" or "PQ"), Components (number connected) |
% | Branch | Tag, Index, From, To (bus tags), Class |
% | Component | Tag, Bus (tag), BusIndex, Position (1, 2, ... on the bus), Class, Key |
% | LocalController | Tag, Component, Bus, Class, Role ("avr", "pss", "governor", "local"), Parent (the AVR of a PSS, else "") |
% | GlobalController | Tag, Class, Units (number of controlled components) |
% | Scenario | Tag, Time ("[t0, tend]"), Description |
%
%   Text columns are string, counts and indices double. A network without elements of the
%   kind gives a table with these columns and no rows.
% - key_table(s_category): one row per model key of GUILDA.keymap(s_category), sorted by
%   Key, with the columns Key, Class and Description (the first help line of the class). It
%   is kept for the MATLAB session and rebuilt when the classes of the key map change.
% - pick(h_parent_figure, tab, ...): a modal window with the search box, the table and the
%   buttons Select and Cancel. It returns the values of one column of
%   the chosen rows ("Tag", or "Key" for a key table), or strings(1,0) on cancel.
%
% The search matches every word typed (separated by spaces) case-insensitively against the
% text of all the columns of a row; a row is shown when it contains all the words. With
% Multiple=true the rows chosen stay chosen while the search hides them. In single mode a
% double click on a row chooses it at once.
%
% One hidden picker window is kept per parent figure and reused: a new call swaps the data
% of its table, so the second opening costs only the new data. The window is recreated when
% it was deleted and is deleted with its parent.
%
% <@Examples>
% ```matlab
% net = network.IEEE68bus();
% tab = DrawerTagPicker.element_table(net, "Component")   % Tag, Bus, BusIndex, Position, Class, Key
% fig = uifigure();
% sv_tag = DrawerTagPicker.pick(fig, tab, Title="Component to remove")
% sv_tag = DrawerTagPicker.pick(fig, DrawerTagPicker.element_table(net, "Bus"), Multiple=true, Selected=["B001", "B002"])
% s_key = DrawerTagPicker.pick(fig, DrawerTagPicker.key_table("Component"), Column="Key")
% ```
%
% See also DrawerOptionDialog, GUILDA.keymap, DrawerGUILDA

    methods(Static)
        tab = element_table(net, s_kind)
        tab = key_table(s_category)
        sv_tag = pick(h_parent_figure, tab, opt)
    end
end
