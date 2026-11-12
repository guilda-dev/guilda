% F32 モデルの GUI (LayerPackage.gui, DrawerModelGUI)
%
%   h = bus.gui();              % 新しい uifigure
%   h = net.gui(h_panel);       % uifigure 系のコンテナの中
%   h.render(comp);             % 対象を切り替えて描き直す
%
% ヘッダ (パンくず・Docs ボタン・stale)・子カード (種類ごと。Parameter は出さない)・
% Parameter タブ (編集で tab_parameter に書き込む)・gui_content の表のページ・固定の配色を
% 確認する。コールバックは見えない uifigure の上で直接呼ぶ。
%
% 実行: runtests("DebugScript.test_F32_model_gui")  または  DebugScript.run_all("Features","F32")

% 共通設定 (各テストの前に毎回実行される)
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
c_fig = onCleanup(@() close_new_figures(findall(groot, "Type", "figure")));


%% A new uifigure opens without a container, in the light theme
h = net.a_Bus{1}.gui();
assert(isa(h, "DrawerModelGUI") && h.a_target == net.a_Bus{1})
assert(isa(h.h_container, "matlab.ui.Figure") && isprop(h.h_container, "isUIFigure"))
assert(contains(header_text(h), "B001") && contains(header_text(h), "Bus"))
assert(isequal(tab_titles(h), ["Parameter","Equilibrium"]))
assert(isempty(findobj(h.h_container, "Type", "uihtml")) && isempty(findobj(h.h_container, "Type", "uiimage")))
if isprop(h.h_container, "Theme")
    assert(h.h_container.Theme.BaseColorStyle == "light")
end


%% The GUI fills a panel of another app and leaves its other components
fig = uifigure("Visible", "off");
g = uigridlayout(fig, [1 2]);
h_other = uilabel(g, "Text", "host");
p = uipanel(g);
h = net.gui(p);
assert(h.h_container == p && h.a_target == net)
assert(numel(p.Children) == 1 && p.Children.Tag == "DrawerModelGUI")
h.render(net.a_Bus{2});
assert(isvalid(h_other) && numel(p.Children) == 1 && h.a_target == net.a_Bus{2})
% A grid layout container keeps the cell of the GUI when it is drawn again
h = net.gui(g);
h_grid = findobj(g.Children, "flat", "Tag", "DrawerModelGUI");
s_cell = [h_grid.Layout.Row, h_grid.Layout.Column];
h.render(net.a_Bus{3});
h_grid = findobj(g.Children, "flat", "Tag", "DrawerModelGUI");
assert(isscalar(h_grid) && isequal([h_grid.Layout.Row, h_grid.Layout.Column], s_cell) && isvalid(h_other))


%% A uitab container works and a figure made by figure() is rejected
fig = uifigure("Visible", "off");
t = uitab(uitabgroup(fig));
h = net.a_Branch{1}.gui(t);
assert(h.h_container == t)
f_old = figure("Visible", "off");
assert(error_id(@() net.gui(f_old)) == "GUILDA:DrawerModelGUI:NotUIContainer")
assert(error_id(@() net.gui(uipanel(f_old))) == "GUILDA:DrawerModelGUI:NotUIContainer")
assert(error_id(@() net.gui(axes(fig))) == "GUILDA:DrawerModelGUI:NotUIContainer")


%% The colors are set on every component and do not follow the theme of the host figure
fig = uifigure("Visible", "off");
if isprop(fig, "Theme")
    fig.Theme = "dark";
end
p = uipanel(uigridlayout(fig, [1 1]));
h = net.a_Bus{1}.a_Component{1}.gui(p);
if isprop(fig, "Theme")
    assert(fig.Theme.BaseColorStyle == "dark")   % the theme of the host is kept
end
h_grid = findobj(p.Children, "flat", "Tag", "DrawerModelGUI");
assert(isequal(h_grid.BackgroundColor, rgb("#F4F6F9")))
h_band = findobj(h_grid, "Type", "uigridlayout", "BackgroundColor", rgb("#005BAA"));
assert(~isempty(h_band) && ~isempty(findobj(h_grid, "Type", "uigridlayout", "BackgroundColor", rgb("#D4DE24"))))
h_table = parameter_tables(h);
assert(all(arrayfun(@(t) isequal(t.BackgroundColor, [rgb("#FBFCFD"); rgb("#F2F5F9")]) ...
    && isequal(t.ForegroundColor, rgb("#23303F")), h_table)))
h_tab = findobj(h_grid, "Type", "uitab");
assert(all(arrayfun(@(t) isequal(t.BackgroundColor, rgb("#F4F6F9")), h_tab)))
h_label = findobj(h_grid, "Type", "uilabel");
assert(all(arrayfun(@(l) isnumeric(l.BackgroundColor) && numel(l.BackgroundColor) == 3, h_label)))
h_panel = findobj(h_grid, "Type", "uipanel");
assert(all(arrayfun(@(q) isequal(q.BackgroundColor, rgb("#FBFCFD")), h_panel)))


%% The breadcrumb runs from the root to the model; a link shows that model
comp = net.a_Bus{1}.a_Component{1};
h = comp.gui();
[h_crumb, l_link] = breadcrumb(h);
assert(numel(h_crumb) == 3 && isequal(l_link, [true true false]))
assert(h_crumb(1).UserData == net && h_crumb(2).UserData == net.a_Bus{1} && h_crumb(3).UserData == comp)
assert(isequal(arrayfun(@(c) string(c.Text), h_crumb).', [string(net.s_tag), "B001", string(comp.s_tag)]))
h_crumb(2).HyperlinkClickedFcn(h_crumb(2), []);
assert(h.a_target == net.a_Bus{1})
[h_crumb, l_link] = breadcrumb(h);
assert(numel(h_crumb) == 2 && isequal(l_link, [true false]))
h_crumb(1).HyperlinkClickedFcn(h_crumb(1), []);
assert(h.a_target == net && isscalar(breadcrumb(h)))


%% The Docs button opens the reference page of the class
h = net.a_Bus{1}.a_Component{1}.gui();
h_docs = findobj(h.h_container, "Type", "uibutton", "Tag", "docs");
assert(isscalar(h_docs) && h_docs.Text == "Docs")
% The callback is not run (it would open a browser); its call and its argument are read instead
sct_fn = functions(h_docs.ButtonPushedFcn);
assert(contains(sct_fn.function, 'GUILDA.doc("class",s_class)'))
assert(sct_fn.workspace{1}.s_class == class(net.a_Bus{1}.a_Component{1}))
h.render(net);
sct_fn = functions(findobj(h.h_container, "Type", "uibutton", "Tag", "docs").ButtonPushedFcn);
assert(sct_fn.workspace{1}.s_class == class(net))


%% The child cards are grouped by kind, without Parameter containers
% A network of its own, since controllers are added to it
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
comp = net.a_Bus{1}.a_Component{1};
h = net.a_Bus{1}.gui();
[h_card, sv_group] = cards(h);
assert(isscalar(h_card) && h_card.UserData == comp && sv_group == "Component (1)")
assert(isequal(h_card.BackgroundColor, rgb("#F1F5D2")) && contains(strjoin(h_card.Text), class(comp)))
% The network: buses, branches, global controllers, then scenarios, each in its own color
agc = net.add_global_controller("agc-PI", {"B001SG1","B002SG1"});
sc  = net.add_scenario("case1");
h.render(net);
[h_card, sv_group] = cards(h);
n_bus = numel(net.a_Bus);
n_br  = numel(net.a_Branch);
assert(numel(h_card) == n_bus + n_br + 2)
assert(isequal(sv_group, ["Bus (" + n_bus + ")", "Branch (" + n_br + ")", "GlobalController (1)", "Scenario (1)"]))
c_model = arrayfun(@(b) b.UserData, h_card, "UniformOutput", false);
assert(isequal(c_model(1:n_bus), net.a_Bus(:)) && c_model{end-1} == agc && c_model{end} == sc)
assert(~any(cellfun(@(c) isa(c, "Parameter"), c_model)))
assert(isequal(h_card(1).BackgroundColor, rgb("#E3EEF8")) && isequal(h_card(n_bus+1).BackgroundColor, rgb("#ECEFF3")))
assert(isequal(h_card(end-1).BackgroundColor, rgb("#ECE6F5")) && isequal(h_card(end).BackgroundColor, rgb("#E0F2EE")))
assert(startsWith(h_card(1).Text(1), "Bus  B001"))
h_nav = ancestor(h_card(1), "uigridlayout");
assert(h_nav.Scrollable == "on")
% A component with a local controller; a model without children has no cards
gen = net.a_Bus{1}.a_Component{1};
avr = gen.add_local_controller("avr-DC1");
h.render(gen);
[h_card, sv_group] = cards(h);
assert(isscalar(h_card) && h_card.UserData == avr && sv_group == "LocalController (1)")
assert(isequal(h_card.BackgroundColor, rgb("#FBEADB")))
h.render(avr);
assert(isempty(cards(h)) && isequal(findobj(h.h_container, "Type", "uitabgroup").Layout.Column, [1 2]))


%% A click on a card shows that model; the context menu opens it in a new window
h = net.a_Bus{1}.gui();
h_card = cards(h);
h_card.ButtonPushedFcn(h_card, []);
comp = net.a_Bus{1}.a_Component{1};
assert(h.a_target == comp && contains(header_text(h), comp.s_tag))
h.render(net);
assert(numel(findall(h.h_container, "Type", "uicontextmenu")) == 1)   % the old menu is removed
% Open in new window
h_card = cards(h);
n_fig = numel(findall(groot, "Type", "figure"));
h_item = h_card(1).ContextMenu.Children(1);
assert(h_item.Text == "Open in new window")
h_item.MenuSelectedFcn(h_item, struct("ContextObject", h_card(1)));
a_fig = findall(groot, "Type", "figure");
assert(numel(a_fig) == n_fig + 1 && any(string({a_fig.Name}) == "Bus B001"))


%% A scenario shows its disturbances and settings, without a Parameter tab
sc = net.add_scenario("case1", Description="fault and ramp");
sc.add_fault("B008", [1,1.05]);
sc.add_input("B002SG1", "Pmech", [0, 0; 1, 0.1], [1,3]);
h = sc.gui();
assert(h.a_target == sc && contains(header_text(h), "case1") && contains(header_text(h), "Scenario"))
assert(isequal(tab_titles(h), ["Disturbances","Settings"]) && isempty(parameter_tables(h)))
assert(isempty(cards(h)) && contains(stale_text(h), "none"))
[h_crumb, l_link] = breadcrumb(h);
assert(numel(h_crumb) == 2 && isequal(l_link, [true false]) && h_crumb(1).UserData == net)
tab = page_data(h, "Disturbances");
assert(height(tab) == 2 && isequal(tab.Tag, ["fault1";"input1"]) && tab.FaultBus(1) == "B008")
assert(tab.TimeSpan(1) == "[1 1.05]" && tab.InputValue(2) == "[0 0;1 0.1]" && tab.InputMethod(2) == "foh")
tab = page_data(h, "Settings");
assert(isequal(tab.Value, ["[0 10]"; "fault and ramp"]))
% The card of the network opens the scenario in a new window
h = net.gui();
h_card = cards(h);
assert(h_card(end).UserData == sc)
n_fig = numel(findall(groot, "Type", "figure"));
h_item = h_card(end).ContextMenu.Children(1);
h_item.MenuSelectedFcn(h_item, struct("ContextObject", h_card(end)));
a_fig = findall(groot, "Type", "figure");
assert(numel(a_fig) == n_fig + 1 && any(string({a_fig.Name}) == "Scenario case1"))
% A removed scenario is deleted, and its view says so
h_card(end).ButtonPushedFcn(h_card(end), []);
net.remove_scenario("case1");
h.render();
assert(contains(strjoin(string(findobj(h.h_container, "Type", "uilabel").Text)), "deleted"))


%% A parameter tab per container; an edit writes tab_parameter and updates the stale state
comp = net.a_Bus{1}.a_Component{1};
h = comp.gui();
assert(isempty(stale_messages(comp)) && contains(stale_text(h), "none"))
sv_tag = string(cellfun(@(p) p.s_tag, comp.a_Parameter, "UniformOutput", false));
h_table = parameter_tables(h);
assert(isequal(sort(string({h_table.Tag})), sort(sv_tag(:).')))
assert(all(string({h_table.ColumnWidth}) == "fit"))
% One column per parameter; the height holds the header, the rows and a scroll bar
h_dyn = findobj(h.h_container, "Type", "uitable", "Tag", "dynamics");
assert(height(h_dyn.Data) == 1 && width(h_dyn.Data) == width(comp.tab_parameter.dynamics))
assert(ancestor(h_dyn, "uigridlayout").RowHeight{1} >= 30 + 24 + 18)
h_note = findobj(h.h_container, "Type", "uilabel", "Tag", "note");
assert(h_note.Text == "See Docs for the meaning of each parameter and the model.")
h_dyn = findobj(h.h_container, "Type", "uitable", "Tag", "dynamics");
tab = h_dyn.Data;
tab.M = tab.M * 2;
h_dyn.Data = tab;
h_dyn.CellEditCallback(h_dyn, []);
assert(comp.tab_parameter.dynamics.M == tab.M)
assert(~isempty(stale_messages(comp)) && contains(stale_text(h), "edit M"))
% Row names of a global controller are shown
agc = net.add_global_controller("agc-PI", {"B001SG1","B002SG1"});
h.render(agc);
h_table = parameter_tables(h);
assert(isequal(string(h_table(1).RowName), ["B001SG1";"B002SG1"]))


%% A value of another class is refused and the table goes back to the stored values
bus = net.a_Bus{2};
h = bus.gui();
h_pf = findobj(h.h_container, "Type", "uitable", "Tag", "powerflow");
tab_old = bus.a_Parameter{cellfun(@(p) p.s_tag == "powerflow", bus.a_Parameter)}.tab_parameter;
tab = h_pf.Data;
tab.V = "abc";                      % string column instead of double
h_pf.Data = tab;
lastwarn("");
DebugScript.helper.quiet(@() h_pf.CellEditCallback(h_pf, []));
assert(contains(lastwarn(), "Parameter powerflow: ") && contains(lastwarn(), "must be double"))   % uialert when visible
assert(isequaln(h_pf.Data, tab_old) && isequaln(bus.tab_parameter.powerflow, tab_old))
assert(isempty(net.sct_stale.powerflow))


%% A deleted model shows a message
b = DebugScript.helper.build_ieee14();
h2 = b.gui(uipanel(uifigure("Visible","off")));
delete(b)
h2.render();
h_label = findobj(h2.h_container, "Type", "uilabel");
assert(isscalar(h_label) && contains(h_label.Text, "deleted"))


%% gui_content pages are tables; a page of another type shows a message
s = DebugScript.helper.GuiContentStub();
h = s.gui();
assert(isequal(tab_titles(h), ["Parameter","Summary","Equilibrium","Table","Unknown"]))
f = h.h_container;
h_tab = findobj(findobj(f, "Type", "uitab", "Tag", "table", "Title", "Table"), "Type", "uitable");
assert(height(h_tab.Data) == 2 && ~any(h_tab.ColumnEditable) && string(h_tab.ColumnWidth) == "fit")
h_label = findobj(findobj(f, "Type", "uitab", "Title", "Unknown"), "Type", "uilabel");
assert(contains(h_label.Text, "Unknown page type: latex"))
assert(isempty(findobj(f, "Type", "uihtml")) && isempty(findobj(f, "Type", "uiimage")))
assert(isempty(findobj(f, "Type", "uibutton", "-not", "Tag", "docs", "-not", "Tag", "child")))


%% The Equilibrium tables are vertical: one row per variable, with Kind, Name and Value
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
avr = gen.add_local_controller("avr-DC1");
h = gen.gui();
assert(isequal(tab_titles(h), ["Parameter","Equilibrium"]))
assert(height(equilibrium_table(h)) == 0 && ~contains(stale_text(h), "none"))
h.render(avr);
assert(height(equilibrium_table(h)) == 0)
% After initialize (run outside the GUI)
DebugScript.helper.quiet(@() net.initialize);
h.render(gen);
assert(isempty(stale_messages(gen)) && contains(stale_text(h), "none"))
tab = equilibrium_table(h);
n_x = numel(gen.rv_Xequilibrium);
n_u = numel(gen.rv_Uequilibrium);
assert(isequal(string(tab.Properties.VariableNames), ["Kind","Name","Value"]))
assert(n_x > 0 && height(tab) == n_x + n_u + 2)
assert(isequal(tab.Kind, [repmat("State",n_x,1); repmat("Input",n_u,1); "Voltage"; "Current"]))
assert(isequal(tab.Name(1:n_x), gen.sv_x(:)) && isequal(tab.Name(end-1:end), ["V";"I"]))
assert(str2double(tab.Value(1)) == round(gen.rv_Xequilibrium(1), 6, "significant"))
assert(endsWith(tab.Value(end), "j") && abs(str2double(tab.Value(end)) - gen.c_Iequilibrium) < 1e-5)
h_table = findobj(findobj(h.h_container, "Type", "uitab", "Title", "Equilibrium"), "Type", "uitable");
assert(string(h_table.ColumnWidth) == "fit" && isequal(h_table.Parent.RowHeight, {'1x'}))
h.render(avr);
tab = equilibrium_table(h);
assert(isempty(stale_messages(avr)) && contains(stale_text(h), "none"))
assert(numel(avr.rv_Xequilibrium) > 0 && height(tab) == numel(avr.rv_Xequilibrium) + numel(avr.rv_Uequilibrium) + 2)
assert(isequal(tab.Name(end-1:end), ["V";"I"]))
% A global controller: names numbered when the inputs of several units do not match sv_u
agc = net.add_global_controller("agc-PI", {"B001SG1","B002SG1"});
DebugScript.helper.quiet(@() net.initialize);
h.render(agc);
tab = equilibrium_table(h);
assert(height(tab) == numel(agc.rv_Xequilibrium) + numel(agc.rv_Uequilibrium))
assert(isequal(string(tab.Properties.VariableNames), ["Kind","Name","Value"]))
if numel(agc.sv_u) ~= numel(agc.rv_Uequilibrium)
    assert(tab.Name(end) == "u" + numel(agc.rv_Uequilibrium))
end
% A bus: one item per row
h.render(net.a_Bus{1});
tab = equilibrium_table(h);
assert(isequal(string(tab.Properties.VariableNames), ["Name","Value"]) && height(tab) == 5)


%% The GUI runs no function of the model: no Initialize page and no action button
[~, gen] = DebugScript.helper.build_3bus("gen-1axis");
h = gen.gui();
assert(~any(tab_titles(h) == "Initialize"))
sv_button = string({findobj(h.h_container, "Type", "uibutton").Tag});
assert(all(ismember(sv_button, ["docs","child"])))


function close_new_figures(a_before)
% テストで開いた図を閉じる
    a_now = findall(groot, "Type", "figure");
    delete(a_now(~ismember(a_now, a_before)))
end

function rv = rgb(s_hex)
% "#RRGGBB" の色の RGB (0〜1)
    rv = double(hex2dec(reshape(char(extractAfter(string(s_hex), 1)), 2, 3).')).' / 255;
end

function [h_crumb, l_link] = breadcrumb(h)
% パンくずの項目 (ルートから順) と、それぞれがリンクかどうか
    h_crumb = findobj(h.h_container, "Tag", "breadcrumb");
    l_link = arrayfun(@(c) isa(c, "matlab.ui.control.Hyperlink"), h_crumb).';
end

function [h_card, sv_group] = cards(h)
% 子カード (並んだ順) と、種類ごとのまとまりの見出し
    h_card = gobjects(0,1);
    sv_group = strings(1,0);
    h_nav = findobj(h.h_container, "Type", "uibutton", "Tag", "child");
    if isempty(h_nav)
        return
    end
    h_child = h_nav(1).Parent.Children;   % 作った順
    h_card = h_child(arrayfun(@(c) c.Tag == "child", h_child));
    sv_group = string({h_child(arrayfun(@(c) c.Tag == "group", h_child)).Text});
end

function s = header_text(h)
    h_lbl = findobj(h.h_container, "Type", "uilabel");
    s = strjoin(string(arrayfun(@(l) strjoin(string(l.Text), newline), h_lbl)), newline);
end

function s = stale_text(h)
    s = strjoin(string(findobj(h.h_container, "Type", "uilabel", "Tag", "stale").Text), newline);
end

function sv = stale_messages(model)
    c = struct2cell(model.sct_stale);
    sv = vertcat(strings(0,1), c{:});
end

function h_table = parameter_tables(h)
    h_table = findobj(findobj(h.h_container, "Type", "uitab", "Title", "Parameter"), "Type", "uitable");
end

function tab = equilibrium_table(h)
    tab = findobj(findobj(h.h_container, "Type", "uitab", "Title", "Equilibrium"), "Type", "uitable").Data;
end

function tab = page_data(h, s_title)
    h_tab = findobj(h.h_container, "Type", "uitab", "Title", s_title);
    tab = findobj(h_tab, "Type", "uitable").Data;
end

function sv = tab_titles(h)
    h_group = findobj(h.h_container, "Type", "uitabgroup");
    sv = string({h_group.Children.Title});
end

function id = error_id(f)
    id = "";
    try
        DebugScript.helper.quiet(f);
    catch me
        id = string(DebugScript.helper.msg_id(me));
    end
end
