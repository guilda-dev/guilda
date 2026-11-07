% F32 モデルの GUI (PowerSystemModel.gui, DrawerModelGUI)
%
%   h = bus.gui();              % 新しい uifigure
%   h = net.gui(h_panel);       % uifigure 系のコンテナの中
%   h.render(comp);             % 対象を切り替えて描き直す
%
% ヘッダ・ツリー (親 → 自身 → 子。Parameter は出さない)・Parameter タブ (編集で
% tab_parameter に書き込む)・gui_content のページを確認する。コールバックは見えない
% uifigure の上で直接呼ぶ。
%
% 実行: runtests("DebugScript.test_F32_model_gui")  または  DebugScript.run_all("Features","F32")

% 共通設定 (各テストの前に毎回実行される)
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
c_fig = onCleanup(@() close_new_figures(findall(groot, "Type", "figure")));


%% A new uifigure opens without a container
h = net.a_Bus{1}.gui();
assert(isa(h, "DrawerModelGUI") && h.a_target == net.a_Bus{1})
assert(isa(h.h_container, "matlab.ui.Figure") && isprop(h.h_container, "isUIFigure"))
assert(contains(header_text(h), "B001") && contains(header_text(h), "Bus"))
assert(isequal(tab_titles(h), ["Parameter","Equilibrium","Image","Initialize"]))   % no Equations: the help of Bus has no math block
assert(isempty(findobj(h.h_container, "Type", "uihtml")))
h_img = findobj(h.h_container, "Type", "uiimage");
assert(endsWith(string(h_img.ImageSource), fullfile("@Bus","image.svg")))


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


%% The tree shows the parent, the model and its children without Parameter containers
comp = net.a_Bus{1}.a_Component{1};
h = net.a_Bus{1}.gui();
h_tree = findobj(h.h_container, "Type", "uitree");
assert(isscalar(h_tree.Children) && h_tree.Children.NodeData == net)
h_self = h_tree.Children.Children;
assert(isscalar(h_self) && h_self.NodeData == net.a_Bus{1} && h_tree.SelectedNodes == h_self)
c_child = arrayfun(@(n) n.NodeData, h_self.Children, "UniformOutput", false);
assert(isequal(c_child, {comp}))
% The network has no parent: it is the root, with buses, branches and global controllers
agc = net.add_global_controller("agc-PI", {"SG1B001","SG1B002"});
h.render(net);
h_tree = findobj(h.h_container, "Type", "uitree");
assert(isscalar(h_tree.Children) && h_tree.Children.NodeData == net)
c_child = arrayfun(@(n) n.NodeData, h_tree.Children.Children, "UniformOutput", false);
assert(numel(c_child) == numel(net.a_Bus) + numel(net.a_Branch) + 1)
assert(~any(cellfun(@(c) isa(c, "Parameter"), c_child)) && c_child{end} == agc)


%% Selecting a node shows that model; the context menu opens it in a new window
h = net.a_Bus{1}.gui();
h_tree = findobj(h.h_container, "Type", "uitree");
h_comp = h_tree.Children.Children.Children(1);
h_tree.SelectionChangedFcn(h_tree, struct("SelectedNodes", h_comp));
comp = net.a_Bus{1}.a_Component{1};
assert(h.a_target == comp && contains(header_text(h), comp.s_tag))
h_tree = findobj(h.h_container, "Type", "uitree");
assert(isscalar(h_tree) && h_tree.SelectedNodes.NodeData == comp)
assert(numel(findall(h.h_container, "Type", "uicontextmenu")) == 1)   % the old menu is removed
% Open in new window
h_bus = h_tree.Children.Children(1);
n_fig = numel(findall(groot, "Type", "figure"));
h_item = h_tree.ContextMenu.Children(1);
assert(h_item.Text == "Open in new window")
h_item.MenuSelectedFcn(h_item, struct("ContextObject", h_bus));
a_fig = findall(groot, "Type", "figure");
assert(numel(a_fig) == n_fig + 1 && any(string({a_fig.Name}) == "Bus B001"))


%% A parameter tab per container; an edit writes tab_parameter and updates the stale state
comp = net.a_Bus{1}.a_Component{1};
h = comp.gui();
assert(isempty(stale_messages(comp)) && contains(stale_text(h), "none"))
sv_tag = string(cellfun(@(p) p.s_tag, comp.a_Parameter, "UniformOutput", false));
h_table = parameter_tables(h);
assert(isequal(sort(string({h_table.Tag})), sort(sv_tag(:).')))
h_dyn = findobj(h.h_container, "Type", "uitable", "Tag", "dynamics");
tab = h_dyn.Data;
tab.M = tab.M * 2;
h_dyn.Data = tab;
h_dyn.CellEditCallback(h_dyn, []);
assert(comp.tab_parameter.dynamics.M == tab.M)
assert(~isempty(stale_messages(comp)) && contains(stale_text(h), "edit M"))
% Row names of a global controller are shown
agc = net.add_global_controller("agc-PI", {"SG1B001","SG1B002"});
h.render(agc);
h_table = parameter_tables(h);
assert(isequal(string(h_table(1).RowName), ["SG1B001";"SG1B002"]))


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


%% Every page type of gui_content is drawn
s = DebugScript.helper.GuiContentStub();
h = s.gui();
assert(isequal(tab_titles(h), ["Parameter","Summary","Equilibrium","Image","Initialize","Equation","Table","Action"]))
f = h.h_container;
h_img = findobj(f, "Type", "uiimage");
assert(endsWith(string(h_img.ImageSource), fullfile("@PowerNetwork","image.svg")))
h_html = findobj(f, "Type", "uihtml");
assert(isscalar(h_html) && ancestor(h_html, "uitab").Title == "Equation")
assert(isequal(h_html.Data.sv_math, ["\dot{x} = f(x,u)"; "y = h(x)"]))
assert(isfile(h_html.HTMLSource) && contains(h_html.Data.s_js, "katex") && contains(h_html.Data.s_css, "data:font/woff2;base64,"))
assert(~contains(h_html.Data.s_css, "url(fonts/"))
h_tab = findobj(findobj(f, "Type", "uitab", "Tag", "table", "Title", "Table"), "Type", "uitable");
assert(height(h_tab.Data) == 2 && ~any(h_tab.ColumnEditable))
% The action runs and the GUI is drawn again
h_btn = findobj(f, "Type", "uibutton", "Text", "Run");
assert(isscalar(h_btn))
h_btn.ButtonPushedFcn(h_btn, []);
assert(s.n_action == 1 && ~isvalid(h_btn))
% An error of the action shows an alert and leaves the GUI as it is
s.l_fail = true;
h_btn = findobj(f, "Type", "uibutton", "Text", "Run");
lastwarn("");
DebugScript.helper.quiet(@() h_btn.ButtonPushedFcn(h_btn, []));
assert(contains(lastwarn(), "action failed"))
assert(s.n_action == 1 && isvalid(h_btn))


%% The Equations page shows the math blocks of the help of the class, after Equilibrium and before Image
[~, gen] = DebugScript.helper.build_3bus("gen-1axis");
h = gen.gui();
sv_title = tab_titles(h);
assert(isequal(sv_title(1:3), ["Parameter","Equilibrium","Equations"]))
assert(~any(sv_title == "Image") || find(sv_title == "Image") > 3)
h_html = findobj(h.h_container, "Type", "uihtml");
assert(isscalar(h_html) && ancestor(h_html, "uitab").Title == "Equations")
sv_math = h_html.Data.sv_math;
assert(numel(sv_math) == count(string(help(class(gen))), "```math"))   % 2 blocks in one_axis
assert(startsWith(sv_math(1), "\left\{") && contains(sv_math(1), "\begin{aligned}") && endsWith(sv_math(1), "\right."))
assert(contains(sv_math(2), "\frac{E_q - V_q}{X_d'}") && ~any(contains(sv_math, "```")))


%% The Equilibrium tables are empty before initialize and filled by the Initialize button
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
avr = gen.add_local_controller("avr-DC1");
h = gen.gui();
assert(isequal(tab_titles(h), ["Parameter","Equilibrium","Equations","Image","Initialize"]))
assert(height(equilibrium_table(h)) == 0 && ~contains(stale_text(h), "none"))
h.render(avr);
assert(height(equilibrium_table(h)) == 0 && any(tab_titles(h) == "Initialize"))
% The button initializes the network and draws the GUI again
h.render(gen);
h_btn = findobj(h.h_container, "Type", "uibutton", "Text", "initialize");
DebugScript.helper.quiet(@() h_btn.ButtonPushedFcn(h_btn, []));
assert(isempty(stale_messages(gen)) && contains(stale_text(h), "none"))
tab = equilibrium_table(h);
n_x = numel(gen.rv_Xequilibrium);
n_u = numel(gen.rv_Uequilibrium);
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
agc = net.add_global_controller("agc-PI", {"SG1B001","SG1B002"});
DebugScript.helper.quiet(@() net.initialize);
h.render(agc);
tab = equilibrium_table(h);
assert(height(tab) == numel(agc.rv_Xequilibrium) + numel(agc.rv_Uequilibrium))
if numel(agc.sv_u) ~= numel(agc.rv_Uequilibrium)
    assert(tab.Name(end) == "u" + numel(agc.rv_Uequilibrium))
end


%% A model outside a network has no Initialize page
[~, gen] = DebugScript.helper.build_3bus("gen-1axis");
avr = gen.add_local_controller("avr-DC1");
gen.remove_local_controller(avr.s_tag);
h = avr.gui();
sv_title = tab_titles(h);
assert(~any(sv_title == "Initialize") && any(sv_title == "Equilibrium"))
assert(isempty(findobj(h.h_container, "Type", "uibutton")))


function close_new_figures(a_before)
% テストで開いた図を閉じる
    a_now = findall(groot, "Type", "figure");
    delete(a_now(~ismember(a_now, a_before)))
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
