function tab = element_table(net, s_kind)
% Return one row per element of one kind of the network, with the columns that tell them apart.
%
% The table is read in a single pass over the layers of the network (handles only: no
% struct(net, false), no copies). The columns by kind are listed in the help of
% DrawerTagPicker; for example, a component row gives its bus, the index of that bus, its
% position among the components of the bus, its class and its model key.
%
% <@Examples>
% ```matlab
% net = network.IEEE68bus();
% tab = DrawerTagPicker.element_table(net, "Component");
% tab(tab.Bus == "B001", :)       % the components of B001 in the order of the bus
% tab = DrawerTagPicker.element_table(net, "LocalController");
% tab(tab.Role == "pss", ["Tag", "Component", "Parent"])
% ```
%
% See also DrawerTagPicker.pick, DrawerTagPicker.key_table
    arguments (Input)
        net    (1,1) PowerNetwork  % Network whose elements are listed.
        s_kind (1,1) string {mustBeMember(s_kind, ["Bus","Branch","Component","LocalController","GlobalController","Scenario"])}  % Kind of the elements.
    end
    arguments (Output)
        tab table  % One row per element; the columns of the kind (see DrawerTagPicker).
    end
    switch s_kind
        case "Bus"
            a_bus = net.a_Bus;
            n = numel(a_bus);
            Tag = strings(n, 1);
            Type = strings(n, 1);
            Components = zeros(n, 1);
            for i = 1:n
                Tag(i) = a_bus{i}.s_tag;
                Type(i) = a_bus{i}.s_bustype;
                Components(i) = numel(a_bus{i}.a_Component);
            end
            Index = (1:n)';
            tab = table(Tag, Index, Type, Components);
        case "Branch"
            a_br = net.a_Branch;
            n = numel(a_br);
            Tag = strings(n, 1);
            From = strings(n, 1);
            To = strings(n, 1);
            Class = strings(n, 1);
            for i = 1:n
                Tag(i) = a_br{i}.s_tag;
                From(i) = a_br{i}.a_Bus{1}.s_tag;
                To(i) = a_br{i}.a_Bus{2}.s_tag;
                Class(i) = class(a_br{i});
            end
            Index = (1:n)';
            tab = table(Tag, Index, From, To, Class);
        case "Component"
            a_bus = net.a_Bus;
            iv_count = zeros(numel(a_bus), 1);
            for i = 1:numel(a_bus)
                iv_count(i) = numel(a_bus{i}.a_Component);
            end
            n = sum(iv_count);
            Tag = strings(n, 1);
            Bus = strings(n, 1);
            BusIndex = zeros(n, 1);
            Position = zeros(n, 1);
            Class = strings(n, 1);
            Key = strings(n, 1);
            j = 0;
            for i = 1:numel(a_bus)
                a_com = a_bus{i}.a_Component;
                for k = 1:iv_count(i)
                    j = j + 1;
                    Tag(j) = a_com{k}.s_tag;
                    Bus(j) = a_bus{i}.s_tag;
                    BusIndex(j) = i;
                    Position(j) = k;
                    Class(j) = class(a_com{k});
                    Key(j) = a_com{k}.key;
                end
            end
            tab = table(Tag, Bus, BusIndex, Position, Class, Key);
        case "LocalController"
            % Depth first: the controllers of a component in slot order, a PSS right after its AVR.
            Tag = strings(0, 1);
            Component = strings(0, 1);
            Bus = strings(0, 1);
            Class = strings(0, 1);
            Role = strings(0, 1);
            Parent = strings(0, 1);
            a_bus = net.a_Bus;
            for i = 1:numel(a_bus)
                a_com = a_bus{i}.a_Component;
                for k = 1:numel(a_com)
                    a_stack = flip(a_com{k}.a_LocalController(:)');
                    while ~isempty(a_stack)
                        con = a_stack{end};
                        a_stack(end) = [];
                        Tag(end+1, 1) = con.s_tag; %#ok<AGROW> a few per component
                        Component(end+1, 1) = a_com{k}.s_tag; %#ok<AGROW>
                        Bus(end+1, 1) = a_bus{i}.s_tag; %#ok<AGROW>
                        Class(end+1, 1) = class(con); %#ok<AGROW>
                        Role(end+1, 1) = con.s_role; %#ok<AGROW>
                        Parent(end+1, 1) = ""; %#ok<AGROW>
                        if isa(con.a_Component, "LocalController")
                            Parent(end) = con.a_Component.s_tag;
                        end
                        a_stack = [a_stack, flip(con.a_LocalController(:)')]; %#ok<AGROW> the PSS under an AVR
                    end
                end
            end
            tab = table(Tag, Component, Bus, Class, Role, Parent);
        case "GlobalController"
            a_con = net.a_GlobalController;
            n = numel(a_con);
            Tag = strings(n, 1);
            Class = strings(n, 1);
            Units = zeros(n, 1);
            for i = 1:n
                Tag(i) = a_con{i}.s_tag;
                Class(i) = class(a_con{i});
                Units(i) = numel(a_con{i}.controlledUnits);
            end
            tab = table(Tag, Class, Units);
        case "Scenario"
            % Public properties only (the disturbance tables of Scenario are being redesigned).
            a_sc = net.a_Scenario;
            n = numel(a_sc);
            Tag = strings(n, 1);
            Time = strings(n, 1);
            Description = strings(n, 1);
            for i = 1:n
                Tag(i) = a_sc{i}.s_tag;
                Time(i) = "[" + a_sc{i}.Time(1) + ", " + a_sc{i}.Time(2) + "]";
                Description(i) = a_sc{i}.Description;
            end
            tab = table(Tag, Time, Description);
    end
end
