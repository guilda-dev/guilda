function disp_summary(obj, opt)
% Display a summary of the network: a list of what it holds, then the tables of its elements.
%
% The list has one item per kind of element: the buses by power-flow type (and the slack
% bus), the branches, components and local controllers by model key (with their tags; at
% most six per key), the global controllers, the scenarios and the state of the
% equilibrium ("up to date"; "out of date" with the first reason, from the stale tags of
% the network, components and controllers; "not computed" before net.initialize()).
% Then come the tables, each switched by its option:
%
% - bus: one row per bus: Tag, Type (slack/PV/PQ), Component (tags of its components).
% - branch: one table per branch model: Tag, From, To.
% - component: one table per component model: Tag, Bus, Controller (tags of its local
%   controllers, the PSS under an AVR included).
%
% parameter adds after each table one table per parameter group of tab_parameter
% (dynamics, operation, powerflow, OPF, graph, ...), each under the heading "<kind> -
% parameter <group>"; a group without parameters is left out. A table wider than 120
% characters is printed in parts, each part starting with the column Tag. equilibrium adds
% the values at the equilibrium:
% Equilibrium (|V| [pu], angle [rad], P, Q [pu] of the bus or component), and for a
% component State and Input. Before net.initialize() (or while a component has no
% equilibrium, e.g. one just added) the equilibrium columns are left out with an INFO
% message (GUILDA:PowerNetwork:SummaryNoEquilibrium). The network is not changed.
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% net.disp_summary()
% net.disp_summary(parameter=false, equilibrium=false)
% net.disp_summary(bus=false, branch=false, component=false)     % the list only
% ```
%
% See also PowerNetwork.get_element_table, PowerNetwork.get_parameter, PowerNetwork.plot_diagram
%
% <@Group> Queries and display
    arguments (Input)
        obj
        opt.equilibrium(1,1) logical = true  % Show the equilibrium values.
        opt.parameter  (1,1) logical = true  % Show the parameters (one table per group).
        opt.bus        (1,1) logical = true  % Show the bus table.
        opt.branch     (1,1) logical = true  % Show the branch tables.
        opt.component  (1,1) logical = true  % Show the component tables.
    end
    tab = obj.get_element_table();
    a_Bus = obj.a_Bus;
    a_Com = tools.vcellfun(@(b) b.a_Component, a_Bus);
    a_Com = [cell(0,1); a_Com];
    sv_type = string(cellfun(@(b) b.s_bustype, a_Bus, "UniformOutput", false));

    % A component without an equilibrium has c_Iequilibrium = [] (the bus values are then
    % placeholders), so the equilibrium is known only when every component has one.
    l_equilibrium = all(cellfun(@(c) ~isempty(c.c_Iequilibrium), a_Com));
    if opt.equilibrium && ~l_equilibrium
        show_msg("info", "GUILDA:PowerNetwork:SummaryNoEquilibrium", char(obj.s_tag));
        opt.equilibrium = false;
    end

    % ---- the list ----
    % "key: n (tag, tag, ...)" for each model key of the rows of one kind
    by_key = @(tab_k) arrayfun(@(s_key) "    - " + s_key + ": " + sum(tab_k.Key == s_key) ...
        + " (" + tag_list(tab_k.Tag(tab_k.Key == s_key)) + ")", unique(tab_k.Key, "stable"));
    % "a n, b m, ..." of the values of a column
    count = @(sv) strjoin(arrayfun(@(s) s + " " + sum(sv == s), unique(sv, "stable")), ", ");
    sct_base = obj.tab_parameter.base;
    sv_line = obj.s_tag + " (" + class(obj) + "): " + sct_base.Hz + " Hz, base " + sct_base.baseMVA + " MVA";

    s_bus = "- Buses: " + numel(a_Bus);
    if ~isempty(a_Bus)
        sv_order = ["slack", "PV", "PQ"];
        sv_have = sv_order(ismember(sv_order, sv_type));
        s_bus = s_bus + " (" + strjoin(arrayfun(@(s) s + " " + sum(sv_type == s), sv_have), ", ") + ")";
        if any(sv_type == "slack")
            s_bus = s_bus + "; slack bus: " + strjoin(string(a_Bus(sv_type == "slack")), ", ");
        else
            s_bus = s_bus + "; no slack bus";
        end
    end
    sv_line(end+1) = s_bus;

    sv_kind  = ["branch", "component", "local", "global"];
    sv_title = ["Branches", "Components", "Local controllers", "Global controllers"];
    for k = 1:numel(sv_kind)
        tab_k = tab(tab.Kind == sv_kind(k), :);
        if isempty(tab_k)
            sv_line(end+1) = "- " + sv_title(k) + ": none"; %#ok<AGROW>
            continue
        end
        s_head = "- " + sv_title(k) + ": " + height(tab_k);
        if sv_kind(k) == "local" || sv_kind(k) == "global"
            s_head = s_head + " (" + count(tab_k.Role) + ")";
        end
        sv_line = [sv_line, s_head, by_key(tab_k).']; %#ok<AGROW>
    end
    if isempty(obj.a_Scenario)
        sv_line(end+1) = "- Scenarios: none";
    else
        sv_line(end+1) = "- Scenarios: " + numel(obj.a_Scenario) + " (" + tag_list(string(obj.a_Scenario)) + ")";
    end
    % out of date: the power flow of the network or the equilibrium of a component or controller
    [c_elem, sv_kind] = element_list(obj);
    c_model = [{obj}; c_elem(ismember(sv_kind, ["component", "local", "global"]))];
    c_stale = cellfun(@(e) [strings(0,1); e.sct_stale.(string(intersect(["powerflow", "equilibrium"], string(fieldnames(e.sct_stale)))))], ...
        c_model, "UniformOutput", false);
    sv_stale = vertcat(c_stale{:});
    if ~l_equilibrium || any(obj.sct_stale.powerflow == obj.s_notInitialized)
        sv_line(end+1) = "- Equilibrium: not computed (run net.initialize())";
    elseif ~isempty(sv_stale)
        sv_line(end+1) = "- Equilibrium: out of date (" + sv_stale(1) + "; run net.initialize())";
    else
        sv_line(end+1) = "- Equilibrium: up to date";
    end
    fprintf("%s\n", sv_line);

    % ---- the tables ----
    % Each kind (or model) gets its table, then one table per parameter group, each under a
    % heading line; a table wider than the page is printed in parts (print_table).
    if opt.bus && ~isempty(a_Bus)
        Tag  = string(a_Bus);
        Type = sv_type;
        Component = string(cellfun(@(b) strjoin([strings(1,0), string(b.a_Component(:)).'], " "), a_Bus, "UniformOutput", false));
        tab_disp = table(Tag, Type, Component);
        if opt.equilibrium
            tab_disp = [tab_disp, table(equilibrium_table(tools.vcellfun(@(b) b.c_Vequilibrium, a_Bus), ...
                tools.vcellfun(@(b) b.c_Iequilibrium, a_Bus)), VariableNames="Equilibrium")];
        end
        print_table("Buses", tab_disp);
        if opt.parameter
            print_parameters("Buses", a_Bus);
        end
    end

    if opt.branch
        for s_key = unique(tab.Key(tab.Kind == "branch"), "stable").'
            lv = tab.Kind == "branch" & tab.Key == s_key;
            Tag = tab.Tag(lv);  From = tab.From(lv);  To = tab.To(lv);
            s_head = "Branches: " + s_key + " (" + tab.Class(find(lv, 1)) + ")";
            print_table(s_head, table(Tag, From, To));
            if opt.parameter
                print_parameters(s_head, obj.a_Branch(ismember(string(obj.a_Branch), Tag)));
            end
        end
    end

    if opt.component
        sv_comp = string(a_Com);
        for s_key = unique(tab.Key(tab.Kind == "component"), "stable").'
            lv  = tab.Kind == "component" & tab.Key == s_key;
            a_k = a_Com(ismember(sv_comp, tab.Tag(lv)));
            Tag = string(a_k);
            Bus = tab.Bus(lv);
            Controller = string(cellfun(@(c) strjoin([strings(1,0), tab.Tag(tab.Kind == "local" ...
                & elements_below(obj, tab.Tag, tab.Parent, c.s_tag)).'], " "), a_k, "UniformOutput", false));
            tab_disp = table(Tag, Bus, Controller);
            if opt.equilibrium
                Equilibrium = equilibrium_table(tools.vcellfun(@(c) c.c_Vequilibrium, a_k), tools.vcellfun(@(c) c.c_Iequilibrium, a_k));
                tab_disp = [tab_disp, table(Equilibrium)]; %#ok<AGROW>
                if ~isempty(a_k{1}.sv_x)
                    tab_disp.State = array2table(tools.vcellfun(@(c) c.rv_Xequilibrium(:).', a_k), VariableNames=a_k{1}.sv_x); %#ok<AGROW>
                end
                if ~isempty(a_k{1}.sv_u)
                    tab_disp.Input = array2table(tools.vcellfun(@(c) c.rv_Uequilibrium(:).', a_k), VariableNames=a_k{1}.sv_u); %#ok<AGROW>
                end
            end
            s_head = "Components: " + s_key + " (" + tab.Class(find(lv, 1)) + ")";
            print_table(s_head, tab_disp);
            if opt.parameter
                print_parameters(s_head, a_k);
            end
        end
    end
end

function print_parameters(s_head, c_elem)
    % One table per parameter group of the elements (Tag and the parameters), empty groups left out
    arguments (Input)
        s_head (1,1) string  % Heading of the elements, e.g. "Buses".
        c_elem (:,1) cell    % Elements of one class.
    end
    Tag = string(cellfun(@(e) char(e.s_tag), c_elem, "UniformOutput", false));
    for i_p = 1:numel(c_elem{1}.a_Parameter)
        s_group = c_elem{1}.a_Parameter{i_p}.s_tag;
        tab_p = tools.vcellfun(@(e) e.a_Parameter{i_p}.tab_parameter, c_elem);
        if width(tab_p) > 0
            tab_p.Properties.RowNames = {};
            print_table(s_head + " - parameter " + s_group, [table(Tag), tab_p]);
        end
    end
end

function print_table(s_head, tab)
    % Heading line, then the table; a table wider than n_width characters is printed in
    % parts of whole columns, each part starting with the first column (Tag)
    arguments (Input)
        s_head (1,1) string  % Heading line.
        tab    table         % Table to print; its first column is Tag.
    end
    n_width = 120;
    fprintf("\n%s\n", s_head);
    i_col = 2;
    while i_col <= width(tab)
        % as many columns as fit (at least one)
        i_end = i_col;
        while i_end < width(tab) && max(strlength(splitlines(formattedDisplayText(tab(:, [1, i_col:i_end+1]))))) <= n_width
            i_end = i_end + 1;
        end
        if i_col > 2
            fprintf("\n");                          % a blank line between the parts
        end
        fprintf("%s", formattedDisplayText(tab(:, [1, i_col:i_end])));
        i_col = i_end + 1;
    end
    if width(tab) == 1
        fprintf("%s", formattedDisplayText(tab));
    end
end

function s = tag_list(sv_tag)
    % At most six tags joined by ", ", then the number of the others
    arguments (Input)
        sv_tag (:,1) string  % Tags.
    end
    arguments (Output)
        s (1,1) string  % "t1, t2, ..., t6, ... (n more)".
    end
    n_max = 6;
    s = strjoin(sv_tag(1:min(end, n_max)).', ", ");
    if numel(sv_tag) > n_max
        s = s + ", ... (" + (numel(sv_tag) - n_max) + " more)";
    end
end

function tab_eq = equilibrium_table(cv_V, cv_I)
    % |V|, angle, P and Q at the equilibrium from the voltage and current phasors
    arguments (Input)
        cv_V (:,1) double  % [pu] Voltage phasors.
        cv_I (:,1) double  % [pu] Current phasors (injected).
    end
    arguments (Output)
        tab_eq table  % Columns V, theta, P, Q.
    end
    cv_S = cv_V .* conj(cv_I);
    tab_eq = table(abs(cv_V), angle(cv_V), real(cv_S), imag(cv_S), VariableNames=["V", "theta", "P", "Q"]);
end
