% F24 タグ
%
% タグは永続 ID。改名は編集ログに記録するが、何も古くならず、既存の機器のタグは追従しない。
%
% 実行: runtests("DebugScript.test_F24_tags")  または  DebugScript.run_all("Features","F24")


%% Renaming a bus is logged with the old and new tags
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
bus = net.a_Bus{2};
bus.str_tag = "BX";

assert(height(net.tab_editLog) == 1)
row = net.tab_editLog(1,:);
assert(row.ID == "BX/" + net.str_tag && row.tag == "Tag" && contains(row.log, "B002") && contains(row.log, "BX"))
assert(row.before{1} == "B002" && row.after{1} == "BX")
assert(DebugScript.helper.edit_flag(net) == "editted")


%% A rename makes nothing stale and analyses run without initialize
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
h_dx = comp.f_dx;
net.a_Bus{2}.str_tag = "BX";

assert(~comp.s_edit.l_staleOdefcn && ~net.s_edit.l_staleEquilibrium)
sol = net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1]));
assert(sol.odeResults.t(end) == 1)
net.get_sys();
net.linearize();
assert(isequal(h_dx, comp.f_dx))


%% Component tags do not follow a bus rename
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
bus = net.a_Bus{2};
str_comp = comp.str_tag;
bus.str_tag = "BX";

assert(comp.str_tag == str_comp && endsWith(str_comp, "B002"))
comp_new = bus.add_component("load-power", "P",-0.1, "Q",-0.1);
assert(endsWith(comp_new.str_tag, "BX"))
assert(comp.str_tag == str_comp)


%% Assigning the same tag is not a rename
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
net.a_Bus{2}.str_tag = "B002";
assert(height(net.tab_editLog) == 0 && DebugScript.helper.edit_flag(net) == "initialized")


%% A tag changed because of an overlap is logged as the final tag
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
evalc("net.a_Bus{2}.str_tag = ""B001"";");
assert(net.a_Bus{2}.str_tag == "B001002")
assert(net.tab_editLog.before{end} == "B002" && net.tab_editLog.after{end} == "B001002")


%% The log is cleared by initialize and building a network logs nothing
[net, ~] = DebugScript.helper.build_3bus("gen-1axis");
net.a_Bus{2}.str_tag = "BX";                % 初回 initialize の前は他の編集と同様に記録しない
assert(height(net.tab_editLog) == 0)
DebugScript.helper.quiet(@() net.initialize);
assert(height(net.tab_editLog) == 0)
net.a_Bus{2}.str_tag = "BY";
assert(height(net.tab_editLog) == 1)
DebugScript.helper.quiet(@() net.initialize);
assert(height(net.tab_editLog) == 0)


%% Renaming a network, branch or component is logged too
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
DebugScript.helper.quiet(@() net.initialize);
net.str_tag = "Renamed";
net.a_Branch{1}.str_tag = "EL_X";
comp.str_tag = "SG_X";
assert(height(net.tab_editLog) == 3 && all(net.tab_editLog.tag == "Tag"))
assert(~net.s_edit.l_staleEquilibrium)
