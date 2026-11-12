% F24 タグ
%
% タグは永続 ID。改名は編集として報告されるが何も古くせず、既存の機器のタグは追従しない。
% タグは MATLAB の変数名として有効な文字列 (isvarname) でなければならず、それ以外は
% GUILDA:LayerPackage:InvalidTag で止まる (重複の番号付けの後も同じ)。
%
% 実行: runtests("DebugScript.test_F24_tags")  または  DebugScript.run_all("Features","F24")


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% Renaming a bus makes nothing stale
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
bus = net.a_Bus{2};
bus.s_tag = "BX";
assert(bus.s_tag == "BX")
assert(isempty(DebugScript.helper.stale(net)) && DebugScript.helper.edit_flag(net) == "initialized")


%% A rename makes nothing stale and analyses run without initialize
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
h_dx = comp.f_dx;
net.a_Bus{2}.s_tag = "BX";

assert(isequal(h_dx, comp.f_dx) && ~DebugScript.helper.is_stale(net))
sol = net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1]));
assert(sol.odeResults.t(end) == 1)
net.get_sys();
net.linearize();
assert(isequal(h_dx, comp.f_dx))      % 解析は何も作り直さない


%% Component tags do not follow a bus rename
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
bus = net.a_Bus{2};
s_comp = comp.s_tag;
bus.s_tag = "BX";

assert(comp.s_tag == s_comp && startsWith(s_comp, "B002"))
comp_new = bus.add_component("load-power", "P",-0.1, "Q",-0.1);
assert(comp_new.s_tag == "BXLPQ1")
assert(comp.s_tag == s_comp)


%% Assigning the same tag is not a rename
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
net.a_Bus{2}.s_tag = "B002";
assert(isempty(DebugScript.helper.stale(net)) && DebugScript.helper.edit_flag(net) == "initialized")


%% A tag changed because of an overlap gets a number suffix
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
evalc("net.a_Bus{2}.s_tag = ""B001"";");
assert(net.a_Bus{2}.s_tag == "B001002")
assert(isempty(DebugScript.helper.stale(net)))


%% Scenarios share the name space of the other children of the network
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
s_out = evalc("sc = net.add_scenario(""B001"");");
assert(sc.s_tag == "B001002" && contains(s_out, "B001002"), s_out)
evalc("net.a_Bus{3}.s_tag = ""case1""; sc.s_tag = ""case1"";");
assert(net.a_Bus{3}.s_tag == "case1" && sc.s_tag == "case1002")
evalc("net.a_Bus{3}.s_tag = ""case1002"";");
assert(net.a_Bus{3}.s_tag == "case1002002")
assert(DebugScript.helper.msg_id(caught(@() set_tag(sc, "not valid"))) == "GUILDA:LayerPackage:InvalidTag")
assert(isempty(DebugScript.helper.stale(net)))


%% Messages of later edits name the new tag
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
comp.s_tag = "GX";
comp.tab_parameter.dynamics.D = comp.tab_parameter.dynamics.D + 1;
assert(all(startsWith(comp.sct_stale.equilibrium, "dynamics/GX: edit D: ")), join(comp.sct_stale.equilibrium, "; "))


%% Renaming a network, branch or component makes nothing stale
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
net.s_tag = "Renamed";
net.a_Branch{1}.s_tag = "EL_X";
comp.s_tag = "SG_X";
assert(~DebugScript.helper.is_stale(net) && isempty(DebugScript.helper.stale(net)))


%% A tag that is not a valid variable name stops with an error
% ネットワーク・母線・送電線・機器・制御器のどれも、改名と作成の両方で止まり、タグは変わらない
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
avr = DebugScript.helper.quiet(@() comp.add_local_controller("avr-ST1"));
a_layer = {net, net.a_Bus{2}, net.a_Branch{1}, comp, avr};
sv_bad  = ["LINE20-1", "1B", "", "a b", "B.1", "end", "Bus#1", string(repmat('a', 1, namelengthmax+1))];
for i = 1:numel(a_layer)
    layer = a_layer{i};
    s_old = layer.s_tag;
    for s_bad = sv_bad
        ME = caught(@() set_tag(layer, s_bad));
        assert(DebugScript.helper.msg_id(ME) == "GUILDA:LayerPackage:InvalidTag", class(layer) + ": " + s_bad)
        assert(layer.s_tag == s_old)
    end
    assert(DebugScript.helper.msg_id(caught(@() set_tag(layer, ["A","B"]))) == "GUILDA:LayerPackage:InvalidTag")
end
ME = caught(@() set_tag(net.a_Bus{1}, "LINE20-1"));
assert(contains(ME.message, "'LINE20-1'") && contains(ME.message, "isvarname"), ME.message)
assert(DebugScript.helper.msg_id(caught(@() PowerNetwork("my-net"))) == "GUILDA:LayerPackage:InvalidTag")
assert(DebugScript.helper.msg_id(caught(@() net.add_bus(FullTag="Sub-7"))) == "GUILDA:LayerPackage:InvalidTag")
assert(DebugScript.helper.msg_id(caught(@() net.add_bus(Tag="1"))) == "GUILDA:LayerPackage:InvalidTag")
assert(numel(net.a_Bus) == 3)


%% A valid tag is accepted
% 英字で始まり英数字と _ だけの名前 (namelengthmax 文字まで) は通る
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
avr = DebugScript.helper.quiet(@() comp.add_local_controller("avr-ST1"));
a_layer = {net, net.a_Bus{2}, net.a_Branch{1}, comp, avr};
for i = 1:numel(a_layer)
    % 層ごとに末尾を変える (兄弟の層と重なると番号が付く)
    s_i = string(char('a'+i-1));
    for s_ok = ["LINE20_1", "G1_TR", "x", "Bus_7"] + s_i
        a_layer{i}.s_tag = s_ok;
        assert(a_layer{i}.s_tag == s_ok)
    end
    for s_ok = [s_i, string(['T', repmat('_', 1, namelengthmax-2)]) + s_i]
        a_layer{i}.s_tag = s_ok;
        assert(a_layer{i}.s_tag == s_ok)
    end
end
assert(net.add_bus(FullTag="Sub_7").s_tag == "Sub_7")


%% The number suffix of an overlap keeps the tag valid
% 重複の番号付け (<tag>002, 003, ...) の結果も変数名として有効。上限の長さを超えるときは止まる
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
evalc("net.a_Bus{2}.s_tag = ""B001"";");
evalc("net.a_Bus{3}.s_tag = ""B001"";");
assert(net.a_Bus{2}.s_tag == "B001002" && net.a_Bus{3}.s_tag == "B001003")
assert(all(arrayfun(@(s) isvarname(char(s)), string(net.a_Bus))))
s_long = string(repmat('L', 1, namelengthmax));
net.a_Bus{1}.s_tag = s_long;
bus2 = net.a_Bus{2};
ME = caught(@() DebugScript.helper.quiet(@() set_tag(bus2, s_long)));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:LayerPackage:InvalidTag" && contains(ME.message, s_long + "002"))
assert(net.a_Bus{2}.s_tag == "B001002")


%% Automatic tags of the built-in networks are valid variable names
% 母線 (B001)、機器 (B001SG1 など)、送電線、制御器の自動のタグと、同梱の CSV の FullTag
for s_net = ["IEEE9bus", "IEEE14bus", "Ishizaki6Bus", "IEEJ_WEST10"]
    net = DebugScript.helper.quiet(@() network.(s_net)());
    a_Comp = tools.vcellfun(@(b) b.a_Component, net.a_Bus);
    a_Lcon = tools.vcellfun(@(c) c.a_LocalController, a_Comp);
    sv_tag = [string(net); string(net.a_Bus); string(net.a_Branch); string(a_Comp); string(a_Lcon); string(net.a_GlobalController)];
    assert(all(arrayfun(@(s) isvarname(char(s)), sv_tag)), s_net + ": " + strjoin(sv_tag(~arrayfun(@(s) isvarname(char(s)), sv_tag)), ", "))
end


%% Labels are the name and the tag of the owner
% 自動のタグは親のタグを含むので、ラベルは名前 + "_" + 所有者のタグだけで網の中で一意
evalc("net = network.Tutorial10bus();");
tab = net.get_variable_map();
sv_expected = ["delta_B001SG1"; "omega_B001SG1CP2"; "Vre_B001"; ...
               "Y_omega_B001SG1"; "xi_PowerNetworkAGC1"; "Pmech_B001SG1_PowerNetworkAGC1"];
assert(all(ismember(sv_expected, tab.Label)), strjoin(sv_expected(~ismember(sv_expected, tab.Label)), ", "))
lv = ismember(tab.Kind, ["x", "u", "Vre", "Vim"]);
assert(isequal(tab.Label(lv), tab.Name(lv) + "_" + tab.Owner(lv)))
assert(net.a_Bus{1}.attach_tag("Vre") == "Vre_B001")


% ---- local functions ----

function ME = caught(fcn)
% fcn を実行し、出たエラーを返す (エラーなしは [])
    ME = [];
    try
        fcn();
    catch ME
    end
end

function set_tag(obj, s_tag)
% obj.s_tag = s_tag (関数ハンドルの中で代入する)
    obj.s_tag = s_tag;
end
