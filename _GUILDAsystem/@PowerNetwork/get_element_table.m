function tab = get_element_table(obj, opt)
% Return a table of the elements of the network, one row per element.
%
% Rows: the buses, branches, components (bus by bus), local controllers (component by
% component, depth first: AVR or "local" controller, the PSS under it, then the governor)
% and global controllers; the row names are the tags (when no two rows share a tag). The scenarios are not model
% elements and have no row (net.get_element finds them). Every column is a string:
%
% - Tag: tag of the element (net.get_element(Tag) returns it).
% - Kind: "bus", "branch", "component", "local" (local controller) or "global" (global controller).
% - Key: model key (e.g. "gen-1axis", "avr-ST1", "pi"); "" for a bus.
% - Class: class name (e.g. "component.generator.one_axis").
% - Role: role of a controller ("avr", "pss", "governor", "local", "agc", ...); "" otherwise.
% - Bus: tag of the bus the element belongs to (a bus: itself; "" for a branch and a global controller).
% - Parent: tag of the parent element (a component: its bus; a local controller: its
%   component, or the AVR for a PSS); "" for the elements directly under the network.
% - From, To: end buses of a branch; "" for the other kinds.
% - State, Input, Output: names of the states, inputs and outputs (sv_x, sv_u, sv_y)
%   joined by ", "; "" for a bus and a branch.
%
% Kind keeps the rows of the given kinds. Owner keeps the elements below the element with
% that tag (its children, their children, ...; not the element itself), e.g. the
% components and controllers of a bus, or the controllers of a generator. The network is
% not changed.
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% tab = net.get_element_table();
% tab(tab.Kind == "component", ["Tag", "Key", "Bus"])
% net.get_element_table(Kind="branch")                 % From and To of each branch
% net.get_element_table(Owner="B001SG1")               % the controllers of a generator
% net.get_element_table(Kind="local").Role             % avr, pss, governor, ...
% ```
%
% See also PowerNetwork.get_element, PowerNetwork.get_parameter, PowerNetwork.disp_summary
%
% <@Group> Queries and display
    arguments (Input)
        obj
        opt.Kind (1,:) string {mustBeMember(opt.Kind, ["bus","branch","component","local","global"])} = ["bus","branch","component","local","global"]  % Kinds of the elements to list.
        opt.Owner (1,1) string = ""  % Tag of an element: list only the elements below it ("": all).
    end
    arguments (Output)
        tab table  % One row per element: Tag, Kind, Key, Class, Role, Bus, Parent, From, To, State, Input, Output (strings).
    end
    [c_elem, sv_kind, sv_parent, sv_bus] = element_list(obj);
    lv = sv_kind ~= "scenario";
    c_elem = c_elem(lv);  sv_kind = sv_kind(lv);  sv_parent = sv_parent(lv);  sv_bus = sv_bus(lv);
    sv_tag = string(cellfun(@(e) e.s_tag, c_elem, "UniformOutput", false));

    lv_keep = ismember(sv_kind, opt.Kind);
    if opt.Owner ~= ""
        lv_keep = lv_keep & elements_below(obj, sv_tag, sv_parent, opt.Owner);
    end

    n = numel(c_elem);
    [Key, Role, From, To, State, Input, Output] = deal(strings(n,1));
    Class = string(cellfun(@class, c_elem, "UniformOutput", false));
    for i = find(lv_keep).'
        e = c_elem{i};
        if sv_kind(i) ~= "bus"
            Key(i) = e.key;
        end
        switch sv_kind(i)
            case "branch"
                From(i) = e.a_Bus{1}.s_tag;
                To(i)   = e.a_Bus{2}.s_tag;
            case {"component", "local", "global"}
                State(i)  = strjoin(e.sv_x, ", ");
                Input(i)  = strjoin(e.sv_u, ", ");
                Output(i) = strjoin(e.sv_y, ", ");
                if sv_kind(i) ~= "component"
                    Role(i) = e.s_role;
                end
        end
    end
    Tag = sv_tag;  Kind = sv_kind;  Bus = sv_bus;  Parent = sv_parent;
    tab = table(Tag, Kind, Key, Class, Role, Bus, Parent, From, To, State, Input, Output);
    tab = tab(lv_keep, :);
    if numel(unique(tab.Tag)) == height(tab)          % tags are unique only among siblings
        tab.Properties.RowNames = tab.Tag;
    end
end
