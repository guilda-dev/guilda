% F18 大域制御器の作成と追加の検査
%
% 不明なタグ、機器でないオブジェクト、別のネットワークの機器は作成時に、ポートの合わない機器は
% 追加時に、それぞれ意図した GUILDA のエラーになることを確認する。
%
% 実行: runtests("DebugScript.test_F18_global_controller")  または  DebugScript.run_all("Features","F18")

%% A valid AGC is accepted, by object and by tag
net = DebugScript.helper.build_ieee14();
agc = net.add_global_controller("agc-PI", {net.a_Bus{1}.a_Component{1}, "SG1B002"});
assert(agc.a_PowerNetwork == net)
assert(isequal(string(agc.controlledUnits), ["SG1B001";"SG1B002"]))


%% An unknown tag stops at construction and the message names it
net = DebugScript.helper.build_ieee14();
[id, s_msg] = error_info(@() net.add_global_controller("agc-PI", "unknown"));
assert(id == "GUILDA:GlobalController:InvalidComponent", id)
assert(contains(s_msg, "'unknown'") && contains(s_msg, "'AGC1"+net.s_tag+"'") && contains(s_msg, "'"+net.s_tag+"'"), s_msg)


%% An object that is not a component stops at construction and the message names its class
net = DebugScript.helper.build_ieee14();
[id, s_msg] = error_info(@() net.add_global_controller("agc-PI", {net.a_Bus{1}}));
assert(id == "GUILDA:GlobalController:InvalidComponent", id)
assert(contains(s_msg, class(net.a_Bus{1})), s_msg)
[id, s_msg] = error_info(@() net.add_global_controller("agc-PI", {1}));
assert(id == "GUILDA:GlobalController:InvalidComponent", id)
assert(contains(s_msg, "'double'"), s_msg)


%% A network without components has nothing to control
net = PowerNetwork("T");
id = error_info(@() net.add_global_controller("agc-PI", "SG1B001"));
assert(id == "GUILDA:GlobalController:InvalidComponent", id)


%% A component of another network is rejected at construction, also when the tag exists here
net   = DebugScript.helper.build_ieee14();
other = DebugScript.helper.build_ieee14();
[id, s_msg] = error_info(@() net.add_global_controller("agc-PI", other.a_Bus{1}.a_Component{1}));
assert(id == "GUILDA:GlobalController:InvalidComponent", id)
assert(contains(s_msg, "SG1B001"), s_msg)


%% A generator without omega is rejected at add, not in simulate
net = PowerNetwork("T");
bus = net.add_bus();
gen = bus.add_component("gen-droop", "P", 0.5);
[id, s_msg] = error_info(@() net.add_global_controller("agc-PI", {gen}));
assert(id == "GUILDA:PowerNetwork:GconPorts", id)
assert(contains(s_msg, "state omega") && contains(s_msg, string(gen.s_tag)) && contains(s_msg, class(gen)), s_msg)
assert(isempty(net.a_GlobalController))


%% A load is rejected at add and the message lists both missing ports
net = PowerNetwork("T");
bus = net.add_bus();
load_comp = bus.add_component("load-power");
[id, s_msg] = error_info(@() net.add_global_controller("agc-PI", {load_comp}));
assert(id == "GUILDA:PowerNetwork:GconPorts", id)
assert(contains(s_msg, "state omega, input Pmech"), s_msg)
assert(isempty(net.a_GlobalController))


%% A checked add leaves the tag free for a valid controller
net = DebugScript.helper.build_ieee14();
assert(error_info(@() net.add_global_controller("agc-PI", "unknown")) == "GUILDA:GlobalController:InvalidComponent")
agc = net.add_global_controller("agc-PI", "SG1B001");
assert(numel(net.a_GlobalController) == 1 && agc.s_tag == "AGC1"+net.s_tag)


function [id, s_msg] = error_info(fh)
% 実行してエラー ID と文面を返す (エラーにならなければ "")
    id = "";
    s_msg = "";
    try
        DebugScript.helper.quiet(fh);
    catch ME
        id = string(DebugScript.helper.msg_id(ME));
        s_msg = string(ME.message);
    end
end
