% F24 タグ
%
% タグは永続 ID。改名は編集として報告されるが何も古くせず、既存の機器のタグは追従しない。
%
% 実行: runtests("DebugScript.test_F24_tags")  または  DebugScript.run_all("Features","F24")


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

assert(comp.s_tag == s_comp && endsWith(s_comp, "B002"))
comp_new = bus.add_component("load-power", "P",-0.1, "Q",-0.1);
assert(endsWith(comp_new.s_tag, "BX"))
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


%% Messages of later edits name the new tag
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
net.a_Bus{2}.s_tag = "BX";
comp.tab_parameter.dynamics.D = comp.tab_parameter.dynamics.D + 1;
assert(all(contains(comp.sct_stale.equilibrium, "/" + comp.s_tag + "/BX/" + net.s_tag + ": edit D: ")))


%% Renaming a network, branch or component makes nothing stale
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
net.s_tag = "Renamed";
net.a_Branch{1}.s_tag = "EL_X";
comp.s_tag = "SG_X";
assert(~DebugScript.helper.is_stale(net) && isempty(DebugScript.helper.stale(net)))
