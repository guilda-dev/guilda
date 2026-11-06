% F17 パラメータの型の誤り (Issue #100, TP5)
%
% 型の誤りは本当のエラーになり、値と古さ (sct_stale) を変えない。正しい編集は従来どおり古さに記録される。
%
% 実行: runtests("DebugScript.test_F17_parameter_type")  または  DebugScript.run_all("Features","F17")

%% Wrong type raises an error and leaves value and log unchanged
[net, ~] = initialized_3bus();
para = net.a_Bus{1}.para_powerflow;
V = para.V;
ME = assign_error(para, "V", "x");
check_error(ME, "V", "double", "string");
assert(para.V == V && isa(para.V, "double"))
assert(isempty(DebugScript.helper.stale(net)))
assert(~DebugScript.helper.is_stale(net))

%% Wrong type raises no warning
[net, ~] = initialized_3bus();
para = net.a_Bus{1}.para_powerflow;
lastwarn("");
assign_error(para, "V", "x");
id = DebugScript.helper.msg_id();
assert(id == "", "warning: " + id)

%% Valid edit is logged once
[net, ~] = initialized_3bus();
para = net.a_Bus{1}.para_powerflow;
V = para.V;
para.V = V + 0.01;
assert(para.V == V + 0.01)
assert(isequal(DebugScript.helper.stale(net), "powerflow/B001/" + net.s_tag + ": edit V: " + tools.value_text(V) + " -> " + tools.value_text(V + 0.01)))
assert(isequal(net.sct_stale.powerflow, DebugScript.helper.stale(net)))

%% Same value is not an edit
[net, ~] = initialized_3bus();
para = net.a_Bus{1}.para_powerflow;
para.V = para.V;
para.Varg = para.Varg;
assert(isempty(DebugScript.helper.stale(net)))

%% Edit after a rejected assignment logs the right previous value
[net, ~] = initialized_3bus();
para = net.a_Bus{1}.para_powerflow;
V = para.V;
assign_error(para, "V", "x");
para.V = V + 0.01;
assert(numel(DebugScript.helper.stale(net)) == 1 && contains(DebugScript.helper.stale(net), "edit V: " + tools.value_text(V) + " -> "))

%% Each parameter of one add_entry keeps its own class
[net, ~] = initialized_3bus();
para = net.a_Branch{1}.para_graph;
MidXaxis = para.MidXaxis;
check_error(assign_error(para, "MidXaxis", 1), "MidXaxis", "string", "double");
assert(isequaln(para.MidXaxis, MidXaxis))
para = net.a_Bus{1}.para_powerflow;
check_error(assign_error(para, "V", "x"), "V", "double", "string");
check_error(assign_error(para, "Varg", "x"), "Varg", "double", "string");

%% Network frequency rejects a wrong type
[net, ~] = initialized_3bus();
Hz = net.para_base.Hz;
check_error(assign_error(net.para_base, "Hz", "60"), "Hz", "double", "string");
assert(net.para_base.Hz == Hz && isempty(DebugScript.helper.stale(net)))

%% Assignment through tab_parameter rejects a wrong type
[net, comp] = initialized_3bus();
comp.add_local_controller(controller.avr.AVR_ST1("avr1"));
DebugScript.helper.quiet(@() net.initialize);
avr = comp.a_LocalController{1};
kap = avr.para_dynamics.kap;
ME = [];
try
    avr.tab_parameter.dynamics.kap = "x";
catch ME
end
assert(~isempty(ME), "エラーが発生しなかった")
check_error(ME, "kap", "double", "string");
assert(avr.para_dynamics.kap == kap && isempty(DebugScript.helper.stale(net)))

%% Check and log are kept after save and load
[net, ~] = initialized_3bus();
s_file = [tempname, '.mat'];
c_file = onCleanup(@() delete(s_file));
save(s_file, "net");
s = load(s_file);
para = s.net.a_Bus{1}.para_powerflow;
V = para.V;
check_error(assign_error(para, "V", "x"), "V", "double", "string");
assert(para.V == V && isempty(DebugScript.helper.stale(s.net)))
para.V = V + 0.01;
assert(numel(DebugScript.helper.stale(s.net)) == 1 && contains(DebugScript.helper.stale(s.net), "edit V: "))


function [net, comp] = initialized_3bus()
% 初期化済みの 3 母線系統を返す
    [net, comp] = DebugScript.helper.build_3bus("gen-park");
    DebugScript.helper.quiet(@() net.initialize);
end

function ME = assign_error(para, name, val)
% 代入して、発生したエラーを返す
    ME = [];
    try
        para.(name) = val;
    catch ME
    end
    assert(~isempty(ME), "エラーが発生しなかった")
end

function check_error(ME, name, valid, cls)
% エラーの ID と、文言のパラメータ名・クラスを確認する
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:Parameter:ClassNameMismatch", "ID が " + DebugScript.helper.msg_id(ME))
    str = string(ME.message);
    assert(contains(str, "'" + name + "' must be " + valid), str)
    assert(contains(str, "class " + cls), str)
end
