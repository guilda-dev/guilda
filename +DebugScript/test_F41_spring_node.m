% F41 ばね質点表示のための機器のノード (Component.get_spring_node) と graph パラメータ
%
%   get_spring_node は列が時刻の行列を受け取り、機器自身のノード (内部電圧のフェーザ)、
%   有効電力、無効電流の大きさ、母線へ注入する電流を返す
%   基底クラス (自身のノードなし) は cv_E = [] で、渡された電流と母線電圧で電力を計算する
%   発電機 5 種は内部電圧を返し、cv_I は fcn_I (f_I) と一致する
%   graph パラメータに MarkerSize (既定 NaN) と Color (既定 "") を追加し、CSV で往復する
%
% 実行: runtests("DebugScript.test_F41_spring_node")  または  DebugScript.run_all("Features","F41")

sv_gen = ["gen-classical", "gen-1axis", "gen-2axis", "gen-park", "gen-droop"];


%% The base class has no own node and uses the given current
[net, comp] = DebugScript.helper.build_3bus("load-power");
DebugScript.helper.quiet(@() net.initialize);
rm_V = [1.0, 0.9; 0.1, -0.2];
rm_I = [0.3, -0.5; -0.4, 0.2];
[cv_E, rv_P, rv_Iq, cv_I] = comp.get_spring_node(zeros(0,2), rm_V, rm_I, zeros(0,2), zeros(1,0));
cv_V = [1,1j]*rm_V;
assert(isequal(size(cv_E), [0,0]), "自身のノードがない機器は []")
assert(isequal(cv_I, [1,1j]*rm_I))
assert(max(abs(rv_P  - real(cv_V.*conj(cv_I)))) < 1e-15)
assert(max(abs(rv_Iq - imag(cv_V.*conj(cv_I))./abs(cv_V))) < 1e-15)
% 静的メソッドなのでクラス名からも呼べる
[cv_E2, rv_P2] = component.load.power.get_spring_node(zeros(0,2), rm_V, rm_I, zeros(0,2), zeros(1,0));
assert(isempty(cv_E2) && isequal(rv_P2, rv_P))


%% Each generator returns its internal voltage and the current of fcn_I
for s_key = sv_gen
    [net, comp] = DebugScript.helper.build_3bus(s_key);
    DebugScript.helper.quiet(@() net.initialize);
    [x, V, u, p] = equilibrium_point(comp);

    [cv_E, rv_P, rv_Iq, cv_I] = comp.get_spring_node(x, V, nan(2,1), u, p);
    c_Ifcn = comp.f_I(0, x, V, u);
    assert(abs(cv_I - c_Ifcn) < 1e-12, s_key + ": cv_I が fcn_I と一致しない")
    assert(abs(cv_I - comp.c_Iequilibrium) < 1e-9, s_key + ": 平衡点の電流と一致しない")
    assert(isscalar(cv_E) && abs(cv_E) > 0.5 && abs(cv_E) < 3, s_key + ": |E| = " + abs(cv_E))
    assert(rv_P > 0, s_key + ": 発電機の有効電力は正")
    c_S = cv_E*conj(cv_I);
    assert(abs(rv_P - real(c_S)) < 1e-15 && abs(rv_Iq - imag(c_S)/abs(cv_E)) < 1e-15)
end


%% The vectorized call equals the calls per column
for s_key = sv_gen
    [net, comp] = DebugScript.helper.build_3bus(s_key);
    DebugScript.helper.quiet(@() net.initialize);
    [x, V, u, p] = equilibrium_point(comp);
    n_t = 4;
    rng(41);
    rm_x = x + 0.05*randn(numel(x), n_t);
    rm_V = V + 0.05*randn(2, n_t);
    rm_u = u + 0.05*randn(numel(u), n_t);

    [cv_E, rv_P, rv_Iq, cv_I] = comp.get_spring_node(rm_x, rm_V, zeros(2,n_t), rm_u, p);
    assert(isequal(size(cv_E), [1,n_t]) && isequal(size(rv_P), [1,n_t]) && ...
           isequal(size(rv_Iq), [1,n_t]) && isequal(size(cv_I), [1,n_t]), s_key + ": 出力は 1 × n_t")
    for k = 1:n_t
        [c_E, r_P, r_Iq, c_I] = comp.get_spring_node(rm_x(:,k), rm_V(:,k), zeros(2,1), rm_u(:,k), p);
        assert(abs(cv_E(k) - c_E) < 1e-14 && abs(rv_P(k) - r_P) < 1e-14 && ...
               abs(rv_Iq(k) - r_Iq) < 1e-14 && abs(cv_I(k) - c_I) < 1e-14, s_key + ": 列 " + k)
        assert(abs(c_I - comp.f_I(0, rm_x(:,k), rm_V(:,k), rm_u(:,k))) < 1e-12, s_key + ": 平衡点以外でも fcn_I と一致")
    end
end


%% Graph defaults and the options of add_bus and add_component
net = PowerNetwork("Graph");
b1  = net.add_bus();
b2  = net.add_bus("MarkerSize", 12, "Color", "red");
c1  = b1.add_component("load-power", "P", -0.1, "Q", 0);
c2  = b2.add_component("load-power", "P", -0.1, "Q", 0, "MarkerSize", 6, "Color", "#00FF7F");
assert(isnan(b1.tab_parameter.graph.MarkerSize) && b1.tab_parameter.graph.Color == "")
assert(isnan(c1.tab_parameter.graph.MarkerSize) && c1.tab_parameter.graph.Color == "")
assert(b2.tab_parameter.graph.MarkerSize == 12 && b2.tab_parameter.graph.Color == "red")
assert(c2.tab_parameter.graph.MarkerSize == 6  && c2.tab_parameter.graph.Color == "#00FF7F")

% replace_component は graph の設定を引き継ぐ (置き換えには平衡点が要るので初期化した系統で)
[net, comp] = DebugScript.helper.build_3bus("load-power");
comp.tab_parameter.graph.MarkerSize = 6;
comp.tab_parameter.graph.Color      = "#00FF7F";
DebugScript.helper.quiet(@() net.initialize);
c3 = DebugScript.helper.quiet(@() comp.a_Bus.replace_component(comp.s_tag, "load-impedance"));
assert(c3.tab_parameter.graph.MarkerSize == 6 && c3.tab_parameter.graph.Color == "#00FF7F")


%% MarkerSize and Color survive a CSV round trip
net = DebugScript.helper.build_3bus("gen-1axis");
net.a_Bus{2}.tab_parameter.graph.MarkerSize = 9;
net.a_Bus{2}.tab_parameter.graph.Color      = "blue";
net.a_Bus{2}.a_Component{1}.tab_parameter.graph.MarkerSize = 4;
net.a_Bus{2}.a_Component{1}.tab_parameter.graph.Color      = "#123456";
[s_dir, c] = temp_folder(); %#ok<ASGLU>
s_path = DebugScript.helper.quiet(@() net.export(fullfile(s_dir, "Net")));
net2 = DebugScript.helper.quiet(@() PowerNetwork.import(s_path, Initialize=false));
assert_graph(net2.a_Bus{2}, 9, "blue")
assert_graph(net2.a_Bus{2}.a_Component{1}, 4, "#123456")
assert_graph(net2.a_Bus{1}, nan, "")                  % 空のセルは既定値に戻る
assert_graph(net2.a_Bus{1}.a_Component{1}, nan, "")


%% Defaults survive a round trip where the whole Color column is empty
net = DebugScript.helper.build_3bus("gen-1axis");
[s_dir, c] = temp_folder(); %#ok<ASGLU>
s_path = DebugScript.helper.quiet(@() net.export(fullfile(s_dir, "Net")));
net2 = DebugScript.helper.quiet(@() PowerNetwork.import(s_path, Initialize=false));
for i = 1:3
    assert_graph(net2.a_Bus{i}, nan, "")
    assert_graph(net2.a_Bus{i}.a_Component{1}, nan, "")
end


%% CSV files without the new columns still import with the defaults
net = DebugScript.helper.build_3bus("gen-1axis");
[s_dir, c] = temp_folder(); %#ok<ASGLU>
s_path = DebugScript.helper.quiet(@() net.export(fullfile(s_dir, "Old")));
remove_cols(fullfile(s_path, "bus", "parameter.csv"));
for s_key = string({dir(fullfile(s_path, "component", "*-*")).name})
    remove_cols(fullfile(s_path, "component", s_key, "main.csv"));
end
net2 = DebugScript.helper.quiet(@() PowerNetwork.import(s_path, Initialize=false));
for i = 1:3
    assert_graph(net2.a_Bus{i}, nan, "")
    assert_graph(net2.a_Bus{i}.a_Component{1}, nan, "")
end


function [x, V, u, p] = equilibrium_point(comp)
    % 平衡点の状態・母線電圧 [Vre; Vim]・入力と、sv_para 順の動的パラメータ
    x = comp.rv_Xequilibrium;
    V = [real(comp.c_Vequilibrium); imag(comp.c_Vequilibrium)];
    u = comp.rv_Uequilibrium;
    p = comp.tab_parameter.dynamics{1, cellstr(comp.sv_para)};
end

function assert_graph(obj, r_size, s_color)
    % graph の MarkerSize と Color を確認する (NaN 同士は一致とみなす)
    tab = obj.tab_parameter.graph;
    assert(isequaln(tab.MarkerSize, r_size), obj.s_tag + ": MarkerSize = " + tab.MarkerSize)
    assert(isstring(tab.Color) && tab.Color == s_color, obj.s_tag + ": Color = " + string(tab.Color))
end

function remove_cols(s_file)
    % MarkerSize と Color の列を削除して書き戻す (列追加前の CSV)
    tab = readtable(s_file, "TextType", "string");
    tab = removevars(tab, intersect(["MarkerSize", "Color"], string(tab.Properties.VariableNames)));
    assert(~any(ismember(["MarkerSize", "Color"], string(tab.Properties.VariableNames))))
    writetable(tab, s_file);
end

function [s_dir, c] = temp_folder()
    s_dir = tempname;
    mkdir(s_dir);
    c = onCleanup(@() rmdir(s_dir, "s"));
end
