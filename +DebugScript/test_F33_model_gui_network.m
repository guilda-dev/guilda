% F33 Bus・Branch・PowerNetwork の GUI のページ (gui_content)
%
%   h = net.gui(fig);           % Parameter → Summary → Equilibrium
%   h = bus.gui(fig);           % Parameter → Equilibrium
%   h = br.gui(fig);            % Parameter → Equilibrium
%
% 各ページの行数と値が、平衡点のプロパティ (c_Vequilibrium, cv_Vequilibrium など) と
% 一致することを、initialize の前後で確かめる。GUI は見えない uifigure に描き、テストの
% 終わりに削除する。
%
% 実行: runtests("DebugScript.test_F33_model_gui_network")  または  DebugScript.run_all("Features","F33")

% 共通設定 (各テストの前に毎回実行される)
net = DebugScript.helper.quiet(@() network.IEEE9bus());
fig = uifigure("Visible", "off");
c_fig = onCleanup(@() delete(fig));


%% The Parameter tab comes first, then the tables of each class (PowerSystemModel adds none)
h = net.gui(fig);
assert(isequal(tab_titles(h), ["Parameter","Summary","Equilibrium"]))
h.render(net.a_Bus{1});
assert(isequal(tab_titles(h), ["Parameter","Equilibrium"]))
h.render(net.a_Branch{1});
assert(isequal(tab_titles(h), ["Parameter","Equilibrium"]))


%% PowerNetwork: Summary counts the buses, branches, components and global controllers
h = net.gui(fig);
tab = page_table(h, "Summary");
assert(isequal(tab.Item, ["Bus";"Branch";"Component";"GlobalController"]))
n_comp = sum(cellfun(@(b) numel(b.a_Component), net.a_Bus));
assert(isequal(tab.Number, [9; numel(net.a_Branch); n_comp; 0]) && n_comp > 0)
net.add_global_controller("agc-PI", {"B001SG1","B002SG1"});
h.render();
tab = page_table(h, "Summary");
assert(tab.Number(4) == 1)


%% PowerNetwork: Equilibrium has one row per bus, before and after initialize
h = net.gui(fig);
check_network(h, net)
cv_old = net.cv_Vequilibrium;
% A changed load makes the power flow stale; the page still shows the stored equilibrium
comp = net.a_Bus{5}.a_Component{1};
comp.tab_parameter.powerflow.P = comp.tab_parameter.powerflow.P * 1.2;
h.render();
check_network(h, net)
assert(isequal(page_table(h, "Equilibrium").V, cv_old))
DebugScript.helper.quiet(@() net.initialize);
h.render();
check_network(h, net)
assert(~isequal(page_table(h, "Equilibrium").V, cv_old))


%% PowerNetwork: a network without buses has empty pages
net0 = DebugScript.helper.quiet(@() PowerNetwork("Empty"));
h = net0.gui(fig);
assert(isequal(page_table(h, "Summary").Number, [0;0;0;0]))
assert(height(page_table(h, "Equilibrium")) == 0)


%% Bus: Equilibrium shows the type, the voltage and the current, before and after initialize
bus = net.a_Bus{5};
h = bus.gui(fig);
check_bus(h, bus)
c_old = bus.c_Vequilibrium;
comp = bus.a_Component{1};
comp.tab_parameter.powerflow.P = comp.tab_parameter.powerflow.P * 1.2;
h.render();
check_bus(h, bus)
assert(bus.c_Vequilibrium == c_old)
DebugScript.helper.quiet(@() net.initialize);
h.render();
check_bus(h, bus)
assert(bus.c_Vequilibrium ~= c_old)
% The slack bus
h.render(net.a_Bus{1});
tab = page_table(h, "Equilibrium");
assert(tab.Value(1) == "slack")


%% Branch: Equilibrium has the from and to ends, before and after initialize
br = net.a_Branch{1};
h = br.gui(fig);
check_branch(h, br)
cv_old = br.cv_Vequilibrium;
comp = net.a_Bus{5}.a_Component{1};
comp.tab_parameter.powerflow.P = comp.tab_parameter.powerflow.P * 1.2;
h.render(net.a_Branch{4});
check_branch(h, net.a_Branch{4})
DebugScript.helper.quiet(@() net.initialize);
h.render(br);
check_branch(h, br)
assert(~isequal(page_table(h, "Equilibrium").V, cv_old))


%% Branch: a removed branch has an empty Equilibrium table
br = net.a_Branch{end};
DebugScript.helper.quiet(@() net.remove_branch(br.s_tag));
assert(isempty(br.a_Bus))
h = br.gui(fig);
tab = page_table(h, "Equilibrium");
assert(height(tab) == 0 && isequal(string(tab.Properties.VariableNames), ["Bus","V","I"]))


function check_network(h, net)
% Equilibrium of the network: Tag, Type, V, |V|, ∠V, I of each bus
    tab = page_table(h, "Equilibrium");
    assert(height(tab) == numel(net.a_Bus))
    assert(isequal(string(tab.Properties.VariableNames), ["Tag","Type","V","|V|","∠V [rad]","I"]))
    assert(isequal(tab.Tag, string(cellfun(@(b) b.s_tag, net.a_Bus, "UniformOutput", false))))
    assert(isequal(tab.Type, string(cellfun(@(b) b.s_bustype, net.a_Bus, "UniformOutput", false))))
    assert(isequal(tab.V, net.cv_Vequilibrium) && isequal(tab.I, net.cv_Iequilibrium))
    assert(isequal(tab.("|V|"), abs(net.cv_Vequilibrium)) && isequal(tab.("∠V [rad]"), angle(net.cv_Vequilibrium)))
end

function check_bus(h, bus)
% Equilibrium of a bus: Type, V, |V|, ∠V, I as display text
    tab = page_table(h, "Equilibrium");
    assert(isequal(tab.Name, ["Type"; "V"; "|V|"; "∠V [rad]"; "I"]))
    assert(tab.Value(1) == bus.s_bustype)
    assert(abs(str2double(replace(tab.Value(2), "j", "i")) - bus.c_Vequilibrium) < 1e-5)
    assert(abs(str2double(tab.Value(3)) - abs(bus.c_Vequilibrium)) < 1e-5)
    assert(abs(str2double(tab.Value(4)) - angle(bus.c_Vequilibrium)) < 1e-5)
    assert(abs(str2double(replace(tab.Value(5), "j", "i")) - bus.c_Iequilibrium) < 1e-5)
end

function check_branch(h, br)
% Equilibrium of a branch: Bus, V, I of the from and to ends
    tab = page_table(h, "Equilibrium");
    assert(height(tab) == 2 && isequal(string(tab.Properties.RowNames), ["from";"to"]))
    assert(isequal(tab.Bus, [string(br.a_Bus{1}.s_tag); string(br.a_Bus{2}.s_tag)]))
    assert(isequal(tab.V, br.cv_Vequilibrium) && isequal(tab.I, br.cv_Iequilibrium))
end

function tab = page_table(h, s_title)
% Table of the page with the title s_title
    h_tab = findobj(h.h_container, "Type", "uitab", "Title", s_title);
    assert(isscalar(h_tab), "no single tab " + s_title)
    tab = findobj(h_tab, "Type", "uitable").Data;
end

function sv = tab_titles(h)
    h_group = findobj(h.h_container, "Type", "uitabgroup");
    sv = string({h_group.Children.Title});
end
