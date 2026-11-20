% F64 発電機の制御器の枠 (案 A: a_LocalController の役割の枠だけが置き場)
%
%   機器の a_LocalController は「AVR か local を 1 つ、調速機を 1 つ」の順で、PSS は AVR の下に
%   1 つだけ付く。gen.avr / gen.pss / gen.governor は役割で探した読み取り専用の値で、
%   gen.set_avr / set_pss / set_governor は add_local_controller の薄い入口。どの書き込み口
%   から入っても枠の検査が働き、1 つの入力を 2 つの制御器が出すとエラーになる。
%
% 実行: runtests("DebugScript.test_F64_controller_slots")  または  DebugScript.run_all("Features","F64")

%% gen.avr, gen.pss and gen.governor return the controllers by role
[~, gen] = DebugScript.helper.build_3bus("gen-park");
% 作った直後は既定の Static の AVR と調速機
assert(isa(gen.avr, "controller.avr.Static") && isempty(gen.pss) && isa(gen.governor, "controller.governor.Static"))
gov = gen.add_local_controller("gov-LPT1");     % 調速機を先に付けても枠の順は変わらない
avr = gen.add_local_controller("avr-ST1");
pss = gen.add_local_controller("pss-PSS1");
assert(gen.avr == avr && gen.pss == pss && gen.governor == gov)
assert(gen.a_LocalController{1} == avr && gen.a_LocalController{2} == gov)
lqr = DebugScript.helper.quiet(@() gen.add_local_controller("local-LQR", parameter=struct(Input="Vfield")));   % AVR の枠を local が置き換える
assert(isempty(gen.avr) && isempty(gen.pss) && gen.governor == gov && gen.a_LocalController{1} == lqr)

%% gen.avr, gen.pss and gen.governor are read-only
[~, gen] = DebugScript.helper.build_3bus("gen-park");
gen.add_local_controller("avr-ST1");
ME = caught(@() set_property(gen, "avr"));
assert(ME.identifier == "MATLAB:class:SetProhibited", ME.identifier)
ME = caught(@() set_property(gen, "governor"));
assert(ME.identifier == "MATLAB:class:SetProhibited", ME.identifier)

%% A second AVR, PSS or governor replaces the first with a warning
[~, gen] = DebugScript.helper.build_3bus("gen-park");
avr1 = gen.add_local_controller("avr-ST1");
pss1 = gen.add_local_controller("pss-PSS1");
gov1 = gen.add_local_controller("gov-LPT1");
lastwarn("", "");
avr2 = DebugScript.helper.quiet(@() gen.add_local_controller("avr-DC1"));
assert(~isvalid(avr1) && gen.avr == avr2 && gen.pss == pss1 && pss1.a_Component == avr2)
pss2 = DebugScript.helper.quiet(@() gen.add_local_controller("pss-PSS1"));
assert(~isvalid(pss1) && gen.pss == pss2)
lastwarn("", "");
gov2 = gen.add_local_controller("gov-LPT1");
assert(string(DebugScript.helper.msg_id()) == "GUILDA:Component:ReplaceController")
assert(~isvalid(gov1) && gen.governor == gov2 && numel(gen.a_LocalController) == 2)
assert(numel(gen.avr.a_LocalController) == 1)

%% set_avr, set_pss and set_governor give the same model as add_local_controller
[net1, gen1] = DebugScript.helper.build_3bus("gen-park");
avr1 = gen1.add_local_controller("avr-ST1", parameter=struct(kap=30));
pss1 = gen1.add_local_controller("pss-PSS1");
gov1 = gen1.add_local_controller("gov-LPT1", parameter=struct(PLM=5));
[net2, gen2] = DebugScript.helper.build_3bus("gen-park");
avr2 = gen2.set_avr("avr-ST1", parameter=struct(kap=30));
pss2 = gen2.set_pss("pss-PSS1");
gov2 = gen2.set_governor("gov-LPT1", parameter=struct(PLM=5));
assert(gen2.avr == avr2 && gen2.pss == pss2 && gen2.governor == gov2)
assert(isequal(string(cellfun(@(c) class(c), gen1.a_LocalController, 'UniformOutput', false)), ...
               string(cellfun(@(c) class(c), gen2.a_LocalController, 'UniformOutput', false))))
assert(avr2.s_tag == avr1.s_tag && pss2.s_tag == pss1.s_tag && gov2.s_tag == gov1.s_tag)
assert(isequaln(avr2.tab_parameter.dynamics, avr1.tab_parameter.dynamics))
assert(isequaln(gov2.tab_parameter.dynamics, gov1.tab_parameter.dynamics))
assert(isequaln(net1.get_variable_map(), net2.get_variable_map()))

%% set_avr, set_pss and set_governor reject a key of another role
[net, gen] = DebugScript.helper.build_3bus("gen-park");
gen.set_avr("avr-ST1");
sv_log = DebugScript.helper.stale(net);
c_case = {@() gen.set_avr("pss-PSS1"), @() gen.set_avr("local-LQR"), @() gen.set_pss("avr-ST1"), ...
          @() gen.set_governor("avr-DC1"), @() gen.set_avr("gov-LPT1")};
for k = 1:numel(c_case)
    ME = caught(c_case{k});
    assert(ME.identifier == "GUILDA:Component:ControllerRoleMismatch", ME.identifier)
end
assert(isequal(DebugScript.helper.stale(net), sv_log) && numel(gen.a_LocalController) == 2 && isempty(gen.pss))   % avr-ST1 と既定の Static の調速機

%% A direct write to a_LocalController of a component is checked against the slots
[~, gen] = DebugScript.helper.build_3bus("gen-park");
avr = gen.add_local_controller("avr-ST1");
pss = gen.add_local_controller("pss-PSS1");
gov = gen.add_local_controller("gov-LPT1");
[~, gen2] = DebugScript.helper.build_3bus("gen-park");
avr2 = gen2.add_local_controller("avr-DC1");
gov2 = gen2.add_local_controller("gov-LPT1");
[comp, c_stub] = DebugScript.helper.stub_component("SlotWriterStub"); %#ok<ASGLU> c_stub が消えると登録が消える
c_bad = {{gov; avr}, {avr; avr2}, {gov; gov2}, {pss}, {avr; gov; gov2}};
a_before = comp.a_LocalController;    % 既定の Static の AVR と調速機
for k = 1:numel(c_bad)
    ME = caught(@() comp.write_slots(c_bad{k}));
    assert(ME.identifier == "GUILDA:Component:ControllerSlots", "%d: %s", k, ME.identifier)
    assert(isequal(numel(comp.a_LocalController), numel(a_before)) && all(cellfun(@eq, comp.a_LocalController, a_before)))
end
comp.write_slots({avr; gov});     % 枠の順なら書ける
assert(comp.avr == avr && comp.governor == gov)
comp.write_slots(cell(0,1));

%% A direct write to the nested slot of a controller holds one PSS under an AVR only
[~, gen] = DebugScript.helper.build_3bus("gen-park");
gen.add_local_controller("avr-ST1");
pss = gen.add_local_controller("pss-PSS1");
gov = gen.add_local_controller("gov-LPT1");
[~, gen2] = DebugScript.helper.build_3bus("gen-park");
gen2.add_local_controller("avr-ST1");
pss2 = gen2.add_local_controller("pss-PSS1");
stub = DebugScript.helper.NestedWriterStub("1");
c_bad = {{gov}, {pss; pss2}, {stub}};
for k = 1:numel(c_bad)
    ME = caught(@() stub.write_nested(c_bad{k}));
    assert(ME.identifier == "GUILDA:LocalController:NestedControllerSlot", "%d: %s", k, ME.identifier)
    assert(isempty(stub.a_LocalController))
end
stub.write_nested({pss});
assert(stub.a_LocalController{1} == pss)
stub.write_nested(cell(0,1));

%% The AVR has no set_PSS: a PSS goes under it through add_local_controller only
assert(~ismethod("controller.avr.AVR_ST1", "set_PSS") && ~ismethod("controller.avr.AVR_DC1", "set_PSS"))

%% An input driven by two local controllers stops the variable map
% add_local_controller が重なりを拒むので、直接の書き込みで作る
[~, genA] = DebugScript.helper.build_3bus("gen-park");
lqr = genA.add_local_controller("local-LQR", parameter=struct(Input="Pmech"));
[~, genB] = DebugScript.helper.build_3bus("gen-park");
gov = genB.add_local_controller("gov-LPT1");
[comp, c_stub] = DebugScript.helper.stub_component("SlotWriterStub"); %#ok<ASGLU>
comp.write_slots({lqr; gov});
ME = caught(@() comp.get_variable_map());
assert(ME.identifier == "GUILDA:Component:InputDrivenTwice", ME.identifier)
assert(contains(ME.message, "'Pmech'") && contains(ME.message, lqr.s_tag) && contains(ME.message, gov.s_tag), ME.message)
comp.write_slots(cell(0,1));


function set_property(obj, s_name)
% 公開プロパティへの代入 (SetProhibited を確かめる)
    obj.(s_name) = [];
end

function ME = caught(fcn)
% fcn を実行してエラーを返す (エラーにならなければ失敗)
    ME = [];
    try
        fcn();
    catch ME
    end
    assert(~isempty(ME), "No error was raised.")
    ME = struct("identifier", string(DebugScript.helper.msg_id(ME)), "message", string(ME.message));
end
