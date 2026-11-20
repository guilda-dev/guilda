% F32 モデルの GUI (LayerPackage.launch_gui, DrawerModelGUI)
%
%   h = bus.launch_gui();              % 新しい uifigure
%   h = net.launch_gui(h_panel);       % uifigure 系のコンテナの中
%   h.render(comp);             % 対象を切り替えて描き直す
%
% ヘッダ (パンくず・Docs ボタン・stale)・子の表 (種類ごと、検索。Parameter は出さない)・
% Parameter タブ (編集はコードとして HistoryGUILDA で実行する)・gui_content の表のページ・
% 固定の配色を確認する。追加・削除の操作は F51 で確かめる。コールバックは見えない uifigure の上で直接呼ぶ。
%
% 実行: runtests("DebugScript.test_F32_model_gui")  または  DebugScript.run_all("Features","F32")

% 共通設定 (各テストの前に毎回実行される)
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
c_fig = onCleanup(@() close_new_figures(findall(groot, "Type", "figure")));
% 図は見えない状態で開く (run_all が設定する既定値に頼らない。見える図では警告の代わりに uialert が出る)
s_vis = get(groot, "DefaultFigureVisible");
set(groot, "DefaultFigureVisible", "off");
c_vis = onCleanup(@() set(groot, "DefaultFigureVisible", s_vis));


%% A new uifigure opens without a container, in the light theme
h = net.a_Bus{1}.launch_gui();
assert(isa(h, "DrawerModelGUI") && h.a_target == net.a_Bus{1})
assert(isa(h.h_container, "matlab.ui.Figure") && isprop(h.h_container, "isUIFigure"))
assert(contains(header_text(h), "B001") && contains(header_text(h), "Bus"))
assert(isequal(tab_titles(h), ["Parameter","Equilibrium"]))
% The Parameter tab and the pages are one uihtml (2026-11-18: option B of the performance work)
assert(isscalar(findobj(h.h_container, "Type", "uihtml")) && isempty(findobj(h.h_container, "Type", "uiimage")))
if isprop(h.h_container, "Theme")
    assert(h.h_container.Theme.BaseColorStyle == "light")
end


%% The GUI fills a panel of another app and leaves its other components
fig = uifigure("Visible", "off");
g = uigridlayout(fig, [1 2]);
h_other = uilabel(g, "Text", "host");
p = uipanel(g);
h = net.launch_gui(p);
assert(h.h_container == p && h.a_target == net)
assert(numel(p.Children) == 1 && p.Children.Tag == "DrawerModelGUI")
h.render(net.a_Bus{2});
assert(isvalid(h_other) && numel(p.Children) == 1 && h.a_target == net.a_Bus{2})
% A grid layout container keeps the cell of the GUI when it is drawn again
h = net.launch_gui(g);
h_grid = findobj(g.Children, "flat", "Tag", "DrawerModelGUI");
s_cell = [h_grid.Layout.Row, h_grid.Layout.Column];
h.render(net.a_Bus{3});
h_grid = findobj(g.Children, "flat", "Tag", "DrawerModelGUI");
assert(isscalar(h_grid) && isequal([h_grid.Layout.Row, h_grid.Layout.Column], s_cell) && isvalid(h_other))


%% A uitab container works and a figure made by figure() is rejected
fig = uifigure("Visible", "off");
t = uitab(uitabgroup(fig));
h = net.a_Branch{1}.launch_gui(t);
assert(h.h_container == t)
f_old = figure("Visible", "off");
assert(error_id(@() net.launch_gui(f_old)) == "GUILDA:DrawerModelGUI:NotUIContainer")
assert(error_id(@() net.launch_gui(uipanel(f_old))) == "GUILDA:DrawerModelGUI:NotUIContainer")
assert(error_id(@() net.launch_gui(axes(fig))) == "GUILDA:DrawerModelGUI:NotUIContainer")


%% The colors are set on every component and do not follow the theme of the host figure
fig = uifigure("Visible", "off");
if isprop(fig, "Theme")
    fig.Theme = "dark";
end
p = uipanel(uigridlayout(fig, [1 1]));
h = net.a_Bus{1}.a_Component{1}.launch_gui(p);
if isprop(fig, "Theme")
    assert(fig.Theme.BaseColorStyle == "dark")   % the theme of the host is kept
end
h_grid = findobj(p.Children, "flat", "Tag", "DrawerModelGUI");
assert(isequal(h_grid.BackgroundColor, rgb("#F4F6F9")))
h_band = findobj(h_grid, "Type", "uigridlayout", "BackgroundColor", rgb("#005BAA"));
assert(~isempty(h_band) && ~isempty(findobj(h_grid, "Type", "uigridlayout", "BackgroundColor", rgb("#D4DE24"))))
% The body gets the colors of the palette as "#RRGGBB"
sct_color = body(h).Data.color;
assert(sct_color.background == "#F4F6F9" && sct_color.card == "#FBFCFD" && sct_color.stripe == "#F2F5F9" ...
    && sct_color.text == "#23303F")
h_label = findobj(h_grid, "Type", "uilabel");
assert(all(arrayfun(@(l) isnumeric(l.BackgroundColor) && numel(l.BackgroundColor) == 3, h_label)))


%% The breadcrumb runs from the root to the model; a link shows that model
comp = net.a_Bus{1}.a_Component{1};
h = comp.launch_gui();
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
h = net.a_Bus{1}.a_Component{1}.launch_gui();
h_docs = findobj(h.h_container, "Type", "uibutton", "Tag", "docs");
assert(isscalar(h_docs) && h_docs.Text == "Docs")
% The callback is not run (it would open a browser); its call and its argument are read instead
sct_fn = functions(h_docs.ButtonPushedFcn);
assert(contains(sct_fn.function, 'GUILDA.doc("class",s_class)'))
assert(sct_fn.workspace{1}.s_class == class(net.a_Bus{1}.a_Component{1}))
h.render(net);
sct_fn = functions(findobj(h.h_container, "Type", "uibutton", "Tag", "docs").ButtonPushedFcn);
assert(sct_fn.workspace{1}.s_class == class(net))


%% The child tables list one kind at a time, without Parameter containers
% A network of its own, since controllers are added to it
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
comp = net.a_Bus{1}.a_Component{1};
h = net.a_Bus{1}.launch_gui();
[c_model, sv_group, h_table] = cards(h);
assert(isscalar(c_model) && c_model{1} == comp && sv_group == "Component (1)")
assert(isequal(string(h_table.Data.Properties.VariableNames), ["Tag", "Class", "Key"]) && h_table.Data.Class == class(comp))
% The network: buses, branches, global controllers, then scenarios, with the columns of element_table
agc = net.add_global_controller("agc-PI", {"B001SG1","B002SG1"});
sc  = net.add_scenario("case1");
h.render(net);
[c_model, sv_group, h_table] = cards(h);
n_bus = numel(net.a_Bus);
n_br  = numel(net.a_Branch);
assert(numel(c_model) == n_bus + n_br + 2)
assert(isequal(sv_group, ["Bus (" + n_bus + ")", "Branch (" + n_br + ")", "GlobalController (1)", "Scenario (1)"]))
assert(isequal(c_model(1:n_bus), net.a_Bus(:)) && c_model{end-1} == agc && c_model{end} == sc)
assert(~any(cellfun(@(c) isa(c, "Parameter"), c_model)))
assert(isequal(string(h_table.Data.Properties.VariableNames), ["Tag", "Type", "Components"]) && h_table.Data.Tag(1) == "B001")
% The search keeps the matching rows; the kind and the search stay for the next render of the model
h_search = findobj(h.h_container, "Tag", "search");
h_search.ValueChangingFcn(h_search, struct("Value", "pv"));
assert(all(h_table.Data.Type == "PV") && numel(h_table.UserData) == height(h_table.Data) && height(h_table.Data) < n_bus)
h_kind = findobj(h.h_container, "Tag", "kind");
h_kind.Value = "Branch";
h_kind.ValueChangedFcn(h_kind, []);
h_search.Value = "";
h_search.ValueChangedFcn(h_search, []);
h_table = findobj(h.h_container, "Type", "uitable", "Tag", "children");    % the table of the branches
assert(height(h_table.Data) == n_br && isequal(string(h_table.Data.Properties.VariableNames), ["Tag", "From", "To", "Class"]))
h.render();
assert(string(findobj(h.h_container, "Tag", "kind").Value) == "Branch")
% The add buttons have the colors of their kinds and short labels
h_add = findobj(h.h_container, "Type", "uibutton", "Tag", "add");
assert(isequal(sort(string({h_add.Text})), sort(["+ Bus", "+ Branch", "+ Controller", "+ Scenario"])))
assert(isequal(h_add(string({h_add.Text}) == "+ Bus").BackgroundColor, rgb("#E3EEF8")))
assert(isequal(h_add(string({h_add.Text}) == "+ Controller").BackgroundColor, rgb("#ECE6F5")))
% A component with its local controllers (the AVR added here and the static governor it has
% from the start); a model without children has no child table
gen = net.a_Bus{1}.a_Component{1};
avr = gen.add_local_controller("avr-DC1");
h.render(gen);
[c_model, sv_group, h_table] = cards(h);
assert(numel(c_model) == 2 && c_model{1} == avr && c_model{2} == gen.governor && sv_group == "LocalController (2)")
assert(isequal(h_table.Data.Role, ["avr"; "governor"]))
assert(isequal(string(h_table.Data.Properties.VariableNames), ["Tag", "Role", "Class"]))
h.render(avr);
assert(isempty(cards(h)) && isequal(body(h).Layout.Column, 2))   % its add button
h.render(net.a_Branch{1});
assert(isempty(cards(h)) && findobj(h.h_container, "Tag", "DrawerModelGUI").ColumnWidth{1} == 0)   % the body takes the width


%% A click on a row shows that model; the context menu opens it in a new window
h = net.a_Bus{1}.launch_gui();
[~, ~, h_table] = cards(h);
h_table.ClickedFcn(h_table, row_event(1));
comp = net.a_Bus{1}.a_Component{1};
assert(h.a_target == comp && contains(header_text(h), comp.s_tag))
h.render(net);
assert(numel(findall(h.h_container, "Type", "uicontextmenu")) == 1)   % the old menu is removed
% Open in new window
[~, ~, h_table] = cards(h);
n_fig = numel(findall(groot, "Type", "figure"));
h_item = findobj(h_table.ContextMenu, "Text", "Open in new window");
assert(isscalar(h_item) && isscalar(findobj(h_table.ContextMenu, "Text", "Remove")))
h_item.MenuSelectedFcn(h_item, row_event(1));
a_fig = findall(groot, "Type", "figure");
assert(numel(a_fig) == n_fig + 1 && any(string({a_fig.Name}) == "Bus B001"))


%% A scenario shows its events, offsets, inputs and settings, without a Parameter tab
sc = net.add_scenario("case1", Description="fault and ramp");
sc.add_fault("B008", [1,1.05]);
sc.add_input("B002SG1", "Pmech", [0, 0; 1, 0.1], [1,3]);
h = sc.launch_gui();
assert(h.a_target == sc && contains(header_text(h), "case1") && contains(header_text(h), "Scenario"))
assert(isequal(tab_titles(h), ["Events","Offsets","Inputs","Settings"]) && isempty(parameter_panels(h)))
assert(isempty(cards(h)) && contains(stale_text(h), "none"))
[h_crumb, l_link] = breadcrumb(h);
assert(numel(h_crumb) == 2 && isequal(l_link, [true false]) && h_crumb(1).UserData == net)
tab = page_data(h, "Events");
assert(height(tab) == 2 && isequal(tab.Tag, ["Fault001";"Fault001"]) && isequal(tab.Target, ["B008";"B008"]))
assert(isequal(tab.Time, ["1";"1.05"]) && isequal(tab.Status, ["BG";"none"]) && isequal(tab.Point, ["";""]))
assert(height(page_data(h, "Offsets")) == 0)
tab = page_data(h, "Inputs");
assert(height(tab) == 1 && tab.Tag == "input1" && tab.TimeSpan == "[1 3]" && tab.InputValue == "[0 0;1 0.1]" && tab.InputMethod == "foh")
tab = page_data(h, "Settings");
assert(isequal(tab.Value, ["[0 10]"; "fault and ramp"]))
% The row of the network opens the scenario in a new window
h = net.launch_gui();
[c_model, ~, h_table] = cards(h, "Scenario");
assert(c_model{end} == sc && h_table.UserData{1} == sc)
n_fig = numel(findall(groot, "Type", "figure"));
h_item = findobj(h_table.ContextMenu, "Text", "Open in new window");
h_item.MenuSelectedFcn(h_item, row_event(1));
a_fig = findall(groot, "Type", "figure");
assert(numel(a_fig) == n_fig + 1 && any(string({a_fig.Name}) == "Scenario case1"))
% A removed scenario is deleted, and its view says so
h_table.ClickedFcn(h_table, row_event(1));
net.remove_scenario("case1");
h.render();
assert(contains(strjoin(string(findobj(h.h_container, "Type", "uilabel").Text)), "deleted"))


%% A parameter tab per container; an edit writes tab_parameter and updates the stale state
comp = net.a_Bus{1}.a_Component{1};
h = comp.launch_gui();
assert(isempty(stale_messages(comp)) && contains(stale_text(h), "none"))
sv_tag = string(cellfun(@(p) p.s_tag, comp.a_Parameter, "UniformOutput", false));
c_panel = parameter_panels(h);
assert(isequal(string(cellfun(@(q) q.tag, c_panel, "UniformOutput", false)), sv_tag(:).'))
% A container of one row of scalars is a vertical Name/Value table with the full names
sct_dyn = panel_of(h, "dynamics");
tab_dyn = comp.tab_parameter.dynamics;
assert(sct_dyn.vertical && sct_dyn.editable && numel(sct_dyn.table.rows) == width(tab_dyn))
assert(isequal(string(sct_dyn.table.rownames), string(tab_dyn.Properties.VariableNames)) && string(sct_dyn.table.cols) == "Value")
assert(body(h).Data.tabs{1}.message == "See Docs for the meaning of each parameter and the model.")
r_M = tab_dyn.M * 2;
edit_cell(h, "dynamics", "M", find(string(sct_dyn.table.rownames) == "M"), string(r_M));
assert(comp.tab_parameter.dynamics.M == r_M)
assert(~isempty(stale_messages(comp)) && contains(stale_text(h), "edit M"))
% A table of several rows keeps one column per parameter, with its row names
agc = net.add_global_controller("agc-PI", {"B001SG1","B002SG1"});
h.render(agc);
c_panel = parameter_panels(h);
sct = c_panel{find(cellfun(@(q) ~q.vertical && numel(q.table.rows) > 1, c_panel), 1)};
assert(isequal(string(sct.table.rownames), ["B001SG1","B002SG1"]) && numel(sct.table.cols) == numel(sct.table.rows{1}))


%% A value of another class is refused and the table goes back to the stored values
bus = net.a_Bus{2};
h = bus.launch_gui();
tab_old = bus.a_Parameter{cellfun(@(p) p.s_tag == "powerflow", bus.a_Parameter)}.tab_parameter;
n_send = body(h).Data.n;
lastwarn("");
DebugScript.helper.quiet(@() edit_cell(h, "powerflow", "V", 1, "abc"));    % text instead of a number
assert(contains(lastwarn(), "Parameter powerflow of B002") && contains(lastwarn(), "abc"), lastwarn())   % uialert when visible
assert(body(h).Data.n > n_send && isequaln(bus.tab_parameter.powerflow, tab_old))   % the stored values are sent again
assert(isempty(net.sct_stale.powerflow))


%% A deleted model shows a message
b = DebugScript.helper.build_ieee14();
h2 = b.launch_gui(uipanel(uifigure("Visible","off")));
delete(b)
h2.render();
h_label = findobj(h2.h_container, "Type", "uilabel");
assert(isscalar(h_label) && contains(h_label.Text, "deleted"))


%% gui_content pages are tables; a page of another type shows a message
s = DebugScript.helper.GuiContentStub();
h = s.launch_gui();
assert(isequal(tab_titles(h), ["Parameter","Summary","Equilibrium","Table","Unknown"]))
f = h.h_container;
c_tab = body(h).Data.tabs;
sct = c_tab{4};
assert(sct.type == "table" && ~sct.events && height(page_data(h, "Table")) == 2)
assert(c_tab{5}.type == "latex" && contains(c_tab{5}.message, "Unknown page type: latex"))
assert(isempty(findobj(f, "Type", "uiimage")))
assert(isempty(findobj(f, "Type", "uibutton", "-not", "Tag", "docs", "-not", "Tag", "add")))


%% The Equilibrium tables are vertical: one row per variable, with Kind, Name and Value
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
avr = gen.add_local_controller("avr-DC1");
h = gen.launch_gui();
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


%% The GUI runs its actions through its history: add buttons, Remove and parameter edits
% 2026-11-14 の決定で GUI から関数を実行する (追加・削除・記録する編集)。詳しくは F51
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
hist = HistoryGUILDA();
h = gen.launch_gui(History=hist);
assert(h.history == hist && hist.get_variable("net") == net)
assert(~any(tab_titles(h) == "Initialize"))
sv_button = string({findobj(h.h_container, "Type", "uibutton").Tag});
assert(all(ismember(sv_button, ["docs","add"])) && sum(sv_button == "add") == 1)
r_M = gen.tab_parameter.dynamics.M * 2;
edit_cell(h, "dynamics", "M", 1, string(r_M));
assert(height(hist.tab_entry) == 1 && ~isempty(regexp(hist.tab_entry.Code, "^net\.a_Bus\{\d+\}\.a_Component\{1\}\.tab_parameter\.dynamics\.M = ", "once")), hist.tab_entry.Code)
assert(hist.tab_entry.Status == "done" && gen.tab_parameter.dynamics.M == r_M)


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
% パンくずの項目 (ルートから順。グリッドの列の順) と、それぞれがリンクかどうか
    h_crumb = findobj(h.h_container, "Tag", "breadcrumb");
    [~, iv] = sort(arrayfun(@(c) c.Layout.Column, h_crumb));
    h_crumb = h_crumb(iv);
    l_link = arrayfun(@(c) isa(c, "matlab.ui.control.Hyperlink"), h_crumb).';
end

function [c_model, sv_group, h_table] = cards(h, s_kind)
% 子の表のすべての種類の子 (種類の順、表の行の順)、種類のドロップダウンの項目、表
% s_kind を渡すと、最後にその種類を表示した状態で返す (省略時は最初の種類に戻す)
    c_model = cell(0, 1);
    sv_group = strings(1, 0);
    h_table = findobj(h.h_container, "Type", "uitable", "Tag", "children");
    if isempty(h_table)
        return
    end
    h_kind = findobj(h.h_container, "Tag", "kind");
    sv_group = string(h_kind.Items);
    sv_kind = string(h_kind.ItemsData);
    for k = sv_kind
        h_kind.Value = k;
        h_kind.ValueChangedFcn(h_kind, []);
        h_table = findobj(h.h_container, "Type", "uitable", "Tag", "children");    % one table per kind of child
        c_model = [c_model; reshape(h_table.UserData, [], 1)]; %#ok<AGROW>
    end
    if nargin < 2
        s_kind = sv_kind(1);
    end
    h_kind.Value = s_kind;
    h_kind.ValueChangedFcn(h_kind, []);
    h_table = findobj(h.h_container, "Type", "uitable", "Tag", "children");
end

function e = row_event(i_row)
% 表の行のクリックとコンテキストメニューのイベントの代わり
    e = struct("InteractionInformation", struct("Row", i_row));
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

function h_body = body(h)
% 本体 (Parameter タブとページ) の uihtml
    h_body = findobj(h.h_container, "Type", "uihtml", "Tag", "body");
end

function c_panel = parameter_panels(h)
% Parameter タブのパネル (コンテナごと。Scenario では空)
    c_tab = body(h).Data.tabs;
    l_para = cellfun(@(t) t.type == "parameter", c_tab);
    c_panel = {};
    if any(l_para)
        c_panel = c_tab{l_para}.panels;
    end
end

function sct = panel_of(h, s_tag)
% タグ s_tag のコンテナのパネル
    c_panel = parameter_panels(h);
    sct = c_panel{cellfun(@(q) q.tag == s_tag, c_panel)};
end

function edit_cell(h, s_tag, s_var, i_row, value)
% Parameter タブのセルの編集 (model_body.html が送るイベントの代わり)
    sct = panel_of(h, s_tag);
    h_body = body(h);
    e = struct("HTMLEventName", "edit", "HTMLEventData", struct("index", sct.index, "var", s_var, "row", i_row, "value", value));
    h_body.HTMLEventReceivedFcn(h_body, e);
end

function tab = equilibrium_table(h)
    tab = page_data(h, "Equilibrium");
end

function tab = page_data(h, s_title)
% ページの表として表示する文字 (列ごとの string)
    c_tab = body(h).Data.tabs;
    sct = c_tab{cellfun(@(t) t.title == s_title, c_tab)}.table;
    sv_col = string(sct.cols);
    sm = strings(numel(sct.rows), numel(sv_col));
    for i = 1:numel(sct.rows)
        sm(i, :) = string(sct.rows{i});
    end
    tab = array2table(sm, "VariableNames", sv_col);
end

function sv = tab_titles(h)
    sv = string(cellfun(@(t) t.title, body(h).Data.tabs, "UniformOutput", false));
end

function id = error_id(f)
    id = "";
    try
        DebugScript.helper.quiet(f);
    catch me
        id = string(DebugScript.helper.msg_id(me));
    end
end
