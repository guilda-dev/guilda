% F17 パラメータの型の誤り (Issue #100, TP5)
%
% 型の誤りは本当のエラーになり、値と古さ (sct_stale) を変えない。正しい編集は従来どおり古さに記録される。
%
% 実行: runtests("DebugScript.test_F17_parameter_type")  または  DebugScript.run_all("Features","F17")

%% Wrong type raises an error and leaves value and log unchanged
[net, ~] = initialized_3bus();
para = net.a_Bus{1}.a_Parameter{cellfun(@(p) p.s_tag=="powerflow", net.a_Bus{1}.a_Parameter)};
V = para.V;
ME = assign_error(para, "V", "x");
check_error(ME, "V", "double", "string");
assert(para.V == V && isa(para.V, "double"))
assert(isempty(DebugScript.helper.stale(net)))
assert(~DebugScript.helper.is_stale(net))

%% Wrong type raises no warning
[net, ~] = initialized_3bus();
para = net.a_Bus{1}.a_Parameter{cellfun(@(p) p.s_tag=="powerflow", net.a_Bus{1}.a_Parameter)};
lastwarn("");
assign_error(para, "V", "x");
id = DebugScript.helper.msg_id();
assert(id == "", "warning: " + id)

%% Valid edit is logged once
[net, ~] = initialized_3bus();
para = net.a_Bus{1}.a_Parameter{cellfun(@(p) p.s_tag=="powerflow", net.a_Bus{1}.a_Parameter)};
V = para.V;
para.V = V + 0.01;
assert(para.V == V + 0.01)
assert(isequal(DebugScript.helper.stale(net), "powerflow/B001/" + net.s_tag + ": edit V: " + tools.value_text(V) + " -> " + tools.value_text(V + 0.01)))
assert(isequal(net.sct_stale.powerflow, DebugScript.helper.stale(net)))

%% Same value is not an edit
[net, ~] = initialized_3bus();
para = net.a_Bus{1}.a_Parameter{cellfun(@(p) p.s_tag=="powerflow", net.a_Bus{1}.a_Parameter)};
para.V = para.V;
para.Varg = para.Varg;
assert(isempty(DebugScript.helper.stale(net)))

%% Edit after a rejected assignment logs the right previous value
[net, ~] = initialized_3bus();
para = net.a_Bus{1}.a_Parameter{cellfun(@(p) p.s_tag=="powerflow", net.a_Bus{1}.a_Parameter)};
V = para.V;
assign_error(para, "V", "x");
para.V = V + 0.01;
assert(numel(DebugScript.helper.stale(net)) == 1 && contains(DebugScript.helper.stale(net), "edit V: " + tools.value_text(V) + " -> "))

%% Each parameter of one add_entry keeps its own class
[net, ~] = initialized_3bus();
para = net.a_Branch{1}.a_Parameter{cellfun(@(p) p.s_tag=="graph", net.a_Branch{1}.a_Parameter)};
MidXaxis = para.MidXaxis;
check_error(assign_error(para, "MidXaxis", 1), "MidXaxis", "string", "double");
assert(isequaln(para.MidXaxis, MidXaxis))
para = net.a_Bus{1}.a_Parameter{cellfun(@(p) p.s_tag=="powerflow", net.a_Bus{1}.a_Parameter)};
check_error(assign_error(para, "V", "x"), "V", "double", "string");
check_error(assign_error(para, "Varg", "x"), "Varg", "double", "string");

%% Network frequency rejects a wrong type
[net, ~] = initialized_3bus();
Hz = net.a_Parameter{cellfun(@(p) p.s_tag=="base", net.a_Parameter)}.Hz;
check_error(assign_error(net.a_Parameter{cellfun(@(p) p.s_tag=="base", net.a_Parameter)}, "Hz", "60"), "Hz", "double", "string");
assert(net.a_Parameter{cellfun(@(p) p.s_tag=="base", net.a_Parameter)}.Hz == Hz && isempty(DebugScript.helper.stale(net)))

%% Assignment through tab_parameter rejects a wrong type
[net, comp] = initialized_3bus();
comp.add_local_controller(controller.avr.AVR_ST1("avr1"));
DebugScript.helper.quiet(@() net.initialize);
avr = comp.a_LocalController{1};
kap = avr.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", avr.a_Parameter)}.kap;
ME = [];
try
    avr.tab_parameter.dynamics.kap = "x";
catch ME
end
assert(~isempty(ME), "エラーが発生しなかった")
check_error(ME, "kap", "double", "string");
assert(avr.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", avr.a_Parameter)}.kap == kap && isempty(DebugScript.helper.stale(net)))

%% Check and log are kept after save and load
[net, ~] = initialized_3bus();
s_file = [tempname, '.mat'];
c_file = onCleanup(@() delete(s_file));
save(s_file, "net");
s = load(s_file);
para = s.net.a_Bus{1}.a_Parameter{cellfun(@(p) p.s_tag=="powerflow", s.net.a_Bus{1}.a_Parameter)};
V = para.V;
check_error(assign_error(para, "V", "x"), "V", "double", "string");
assert(para.V == V && isempty(DebugScript.helper.stale(s.net)))
para.V = V + 0.01;
assert(numel(DebugScript.helper.stale(s.net)) == 1 && contains(DebugScript.helper.stale(s.net), "edit V: "))


%% tab_parameter writes only the changed values
[net, comp] = initialized_3bus();
tp = comp.tab_parameter;
comp.tab_parameter = tp;
assert(isempty(DebugScript.helper.stale(net)), "変わらない値は記録しない")
tp.dynamics.D = tp.dynamics.D + 1;
tp.powerflow.P = tp.powerflow.P;
comp.tab_parameter = tp;
sv = DebugScript.helper.stale(net);
assert(numel(sv) == 1 && contains(sv, "edit D: "), "変えた値だけを記録する")

%% tab_parameter rejects an equal value of another class
[net, ~] = initialized_3bus();
bus = net.a_Bus{1};
tp  = bus.tab_parameter;
V   = tp.powerflow.V;
tp.powerflow.V = single(V);
ME = [];
try
    bus.tab_parameter = tp;
catch ME
end
assert(~isempty(ME), "エラーが発生しなかった")
check_error(ME, "V", "double", "single");
assert(isa(bus.tab_parameter.powerflow.V, "double") && isempty(DebugScript.helper.stale(net)))

%% tab_parameter rejects an unknown column and writes nothing
[net, ~] = initialized_3bus();
bus = net.a_Bus{1};
tp  = bus.tab_parameter;
V   = tp.powerflow.V;
tp.powerflow.V = V + 0.01;
tp.unknown = table(1, 'VariableNames', "x");
ME = [];
try
    bus.tab_parameter = tp;
catch ME
end
assert(DebugScript.helper.msg_id(ME) == "GUILDA:PowerSystemModel:UnknownParameterGroup", DebugScript.helper.msg_id(ME))
assert(contains(ME.message, "'unknown'"), ME.message)
assert(bus.tab_parameter.powerflow.V == V && isempty(DebugScript.helper.stale(net)))

%% Global controller rows are named by its controlled units
net = DebugScript.helper.build_ieee14();
g1  = net.a_Bus{1}.a_Component{1};
g2  = net.a_Bus{2}.a_Component{1};
agc = controller.agc.broadcast_PI_AGC(net, "agc", g1, g2, alpha=[1;1], beta=[1;1], kP=100, kI=500);
net.add_global_controller(agc);
tp = agc.tab_parameter;
assert(isequal(string(tp.dynamics.Properties.RowNames), [string(g1); string(g2)]))
tab = tp.dynamics;
tab{string(g2), "kP"} = 300;
tp.dynamics = tab;
agc.tab_parameter = tp;
assert(isequal(agc.tab_parameter.dynamics.kP, [100; 300]))
assert(isequal(string(agc.tab_parameter.dynamics.Properties.RowNames), [string(g1); string(g2)]))

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
