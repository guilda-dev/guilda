% F17 パラメータの型の誤り (Issue #100, TP5)
%
% 型の誤りは本当のエラーになり、値と編集履歴を変えない。正しい編集は従来どおり記録される。
%
% 実行: runtests("DebugScript.test_F17_parameter_type")  または  DebugScript.run_all("Features","F17")

%% Wrong type raises an error and leaves value and log unchanged
[net, ~] = initialized_3bus();
para = net.a_Bus{1}.para_powerflow;
V = para.V;
ME = assign_error(para, "V", "x");
check_error(ME, "V", "double", "string");
assert(para.V == V && isa(para.V, "double"))
assert(height(net.tab_editLog) == 0)
assert(~net.s_edit.l_staleEquilibrium)

%% Wrong type raises no warning
[net, ~] = initialized_3bus();
para = net.a_Bus{1}.para_powerflow;
lastwarn("");
assign_error(para, "V", "x");
[~, id] = lastwarn;
assert(id == "", "warning: " + id)

%% Valid edit is logged once
[net, ~] = initialized_3bus();
para = net.a_Bus{1}.para_powerflow;
V = para.V;
para.V = V + 0.01;
assert(para.V == V + 0.01)
assert(height(net.tab_editLog) == 1 && net.tab_editLog.log == "edit V")
assert(net.tab_editLog.before{1} == V && net.tab_editLog.after{1} == V + 0.01)
assert(net.s_edit.l_staleEquilibrium)

%% Same value is not an edit
[net, ~] = initialized_3bus();
para = net.a_Bus{1}.para_powerflow;
para.V = para.V;
para.Varg = para.Varg;
assert(height(net.tab_editLog) == 0)

%% Edit after a rejected assignment logs the right previous value
[net, ~] = initialized_3bus();
para = net.a_Bus{1}.para_powerflow;
V = para.V;
assign_error(para, "V", "x");
para.V = V + 0.01;
assert(height(net.tab_editLog) == 1 && net.tab_editLog.before{1} == V)

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
assert(net.para_base.Hz == Hz && height(net.tab_editLog) == 0)

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
assert(avr.para_dynamics.kap == kap && height(net.tab_editLog) == 0)

%% Check and log are kept after save and load
[net, ~] = initialized_3bus();
str_file = [tempname, '.mat'];
c_file = onCleanup(@() delete(str_file));
save(str_file, "net");
s = load(str_file);
para = s.net.a_Bus{1}.para_powerflow;
V = para.V;
check_error(assign_error(para, "V", "x"), "V", "double", "string");
assert(para.V == V && height(s.net.tab_editLog) == 0)
para.V = V + 0.01;
assert(height(s.net.tab_editLog) == 1 && s.net.tab_editLog.log == "edit V")


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
    assert(ME.identifier == "GUILDA:Parameter:ClassNameMismatch", "ID が " + ME.identifier)
    str = string(ME.message);
    assert(contains(str, "'" + name + "' must be " + valid), str)
    assert(contains(str, "class " + cls), str)
end
