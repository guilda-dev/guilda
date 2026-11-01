% F18 大域制御器の作成と追加の検査
%
% 不明なタグ、機器でないオブジェクト、別のネットワークの機器は作成時に、別のネットワーク用の
% 大域制御器とポートの合わない機器は追加時に、それぞれ意図した GUILDA のエラーになることを確認する。
%
% 実行: runtests("DebugScript.test_F18_global_controller")  または  DebugScript.run_all("Features","F18")

%% A valid AGC is accepted, by object and by tag
net = DebugScript.helper.build_ieee14();
agc = controller.agc.broadcast_PI_AGC(net, "agc", net.a_Bus{1}.a_Component{1}, "SG1B002");
net.add_global_controller(agc);
assert(agc.a_PowerNetwork == net)
assert(isequal(string(agc.controlledUnits), ["SG1B001";"SG1B002"]))


%% An unknown tag stops at construction and the message names it
net = DebugScript.helper.build_ieee14();
[id, str_msg] = error_info(@() controller.agc.broadcast_PI_AGC(net, "agc", "unknown"));
assert(id == "GUILDA:GlobalController:InvalidComponent", id)
assert(contains(str_msg, "'unknown'") && contains(str_msg, "'agc'") && contains(str_msg, "'"+net.str_tag+"'"), str_msg)


%% An object that is not a component stops at construction and the message names its class
net = DebugScript.helper.build_ieee14();
[id, str_msg] = error_info(@() controller.agc.broadcast_PI_AGC(net, "agc", net.a_Bus{1}));
assert(id == "GUILDA:GlobalController:InvalidComponent", id)
assert(contains(str_msg, class(net.a_Bus{1})), str_msg)
[id, str_msg] = error_info(@() controller.agc.broadcast_PI_AGC(net, "agc", 1));
assert(id == "GUILDA:GlobalController:InvalidComponent", id)
assert(contains(str_msg, "'double'"), str_msg)


%% A network without components has nothing to control
net = PowerNetwork("T");
id = error_info(@() controller.agc.broadcast_PI_AGC(net, "agc", "SG1B001"));
assert(id == "GUILDA:GlobalController:InvalidComponent", id)


%% A component of another network is rejected at construction, also when the tag exists here
net   = DebugScript.helper.build_ieee14();
other = DebugScript.helper.build_ieee14();
[id, str_msg] = error_info(@() controller.agc.broadcast_PI_AGC(net, "agc", other.a_Bus{1}.a_Component{1}));
assert(id == "GUILDA:GlobalController:InvalidComponent", id)
assert(contains(str_msg, "SG1B001"), str_msg)


%% A controller built on another network is rejected at add, also for an identical network
net   = DebugScript.helper.build_ieee14();
other = DebugScript.helper.build_ieee14();
agc   = controller.agc.broadcast_PI_AGC(other, "agc", "SG1B001");
[id, str_msg] = error_info(@() net.add_global_controller(agc));
assert(id == "GUILDA:PowerNetwork:GconOtherNetwork", id)
assert(contains(str_msg, "'agc'") && contains(str_msg, "'SG1B001'"), str_msg)
assert(isempty(net.a_GlobalController) && isempty(agc.a_PowerNetwork))


%% A component removed after construction is rejected at add
net = DebugScript.helper.build_ieee14();
agc = controller.agc.broadcast_PI_AGC(net, "agc", "SG1B002");
net.a_Bus{2}.remove_component("SG1B002");
id = error_info(@() net.add_global_controller(agc));
assert(id == "GUILDA:PowerNetwork:GconOtherNetwork", id)
assert(isempty(net.a_GlobalController))


%% A generator without omega is rejected at add, not in simulate
net = PowerNetwork("T");
bus = net.add_bus();
gen = bus.add_component("gen-droop", "P", 0.5);
agc = controller.agc.broadcast_PI_AGC(net, "agc", gen);
[id, str_msg] = error_info(@() net.add_global_controller(agc));
assert(id == "GUILDA:PowerNetwork:GconPorts", id)
assert(contains(str_msg, "state omega") && contains(str_msg, string(gen.str_tag)) && contains(str_msg, class(gen)), str_msg)
assert(isempty(net.a_GlobalController) && isempty(agc.a_PowerNetwork))


%% A load is rejected at add and the message lists both missing ports
net = PowerNetwork("T");
bus = net.add_bus();
load_comp = bus.add_component("load-power");
agc = controller.agc.broadcast_PI_AGC(net, "agc", load_comp);
[id, str_msg] = error_info(@() net.add_global_controller(agc));
assert(id == "GUILDA:PowerNetwork:GconPorts", id)
assert(contains(str_msg, "state omega, input Pmech"), str_msg)
assert(isempty(net.a_GlobalController))


%% A checked add leaves the tag free for a valid controller
net = DebugScript.helper.build_ieee14();
bad = controller.agc.broadcast_PI_AGC(DebugScript.helper.build_ieee14(), "agc", "SG1B001");
assert(error_info(@() net.add_global_controller(bad)) == "GUILDA:PowerNetwork:GconOtherNetwork")
net.add_global_controller(controller.agc.broadcast_PI_AGC(net, "agc", "SG1B001"));
assert(numel(net.a_GlobalController) == 1)


function [id, str_msg] = error_info(fh)
% 実行してエラー ID と文面を返す (エラーにならなければ "")
    id = "";
    str_msg = "";
    try
        DebugScript.helper.quiet(fh);
    catch ME
        id = string(ME.identifier);
        str_msg = string(ME.message);
    end
end
