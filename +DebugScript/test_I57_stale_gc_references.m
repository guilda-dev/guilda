% I57 大域制御器が参照する機器の削除と差し替え
%
% 制御対象の remove_component / replace_component が拒否され、古い参照を持つ大域制御器で
% simulate が古い添字を読まずにエラーになることを確認する。
%
% 実行: runtests("DebugScript.test_I57_stale_gc_references")  または  DebugScript.run_all("Features","I57")

%% remove_component rejects a controlled component and changes nothing
[net, agc, bus, comp] = build_controlled_network();
assert(error_id(@() bus.remove_component("SG1B002")) == "GUILDA:Bus:ComponentControlled")
assert(bus.a_Component{1} == comp && comp.a_Bus == bus)


%% replace_component rejects a controlled component and changes nothing
[net, agc, bus, comp] = build_controlled_network();
assert(error_id(@() bus.replace_component("SG1B002", "gen-classical")) == "GUILDA:Bus:ComponentControlled")
assert(bus.a_Component{1} == comp && comp.a_Bus == bus)


%% The component can be edited after removing the global controller
[net, agc, bus, comp] = build_controlled_network();
net.remove_global_controller("agc");
bus.replace_component("SG1B002", "gen-classical");
bus.remove_component("SG1B002");
assert(~ismember("SG1B002", string(bus.a_Component)))


%% A component no controller controls can still be edited
[net, agc, bus, comp] = build_controlled_network();
bus3 = net.a_Bus{3};
str_tag = string(bus3.a_Component{1});
new = bus3.replace_component(str_tag, "gen-classical");
assert(bus3.a_Component{1} == new)
bus3.remove_component(str_tag);
assert(~ismember(str_tag, string(bus3.a_Component)))


%% simulate rejects a controller that kept a removed component, also after an earlier run
[net, agc, bus, comp] = build_controlled_network();
DebugScript.helper.quiet(@() net.initialize);
[~, flag] = DebugScript.helper.quiet(@() net.simulate([0,0.1]));
assert(flag == 1)
net.remove_global_controller("agc");
bus.remove_component("SG1B002");
net.add_global_controller(agc);
DebugScript.helper.quiet(@() net.initialize);
assert(error_id(@() net.simulate([0,0.1])) == "GUILDA:odeSimulator:ForeignControlledUnit")


%% simulate rejects a controller that kept a replaced component with the same tag
[net, agc, bus, comp] = build_controlled_network();
net.remove_global_controller("agc");
new = bus.replace_component("SG1B002", "gen-classical");
assert(string(new) == "SG1B002")
net.add_global_controller(agc);
DebugScript.helper.quiet(@() net.initialize);
assert(error_id(@() net.simulate([0,0.1])) == "GUILDA:odeSimulator:ForeignControlledUnit")


%% simulate rejects a controller built for another network
[net, agc, bus, comp] = build_controlled_network();
other = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() other.initialize);
other.add_global_controller(controller.agc.broadcast_PI_AGC(net, "agc", "SG1B001"));
DebugScript.helper.quiet(@() other.initialize);
assert(error_id(@() other.simulate([0,0.1])) == "GUILDA:odeSimulator:ForeignControlledUnit")


%% A correct controller still simulates
[net, agc, bus, comp] = build_controlled_network();
DebugScript.helper.quiet(@() net.initialize);
[~, flag] = DebugScript.helper.quiet(@() net.simulate([0,0.1]));
assert(flag == 1)


function [net, agc, bus, comp] = build_controlled_network()
% AGC が SG1B001, SG1B002 を制御する IEEE14 (bus は SG1B002 の母線、comp はその発電機)
    net = DebugScript.helper.build_ieee14();
    DebugScript.helper.quiet(@() net.initialize);
    agc = controller.agc.broadcast_PI_AGC(net, "agc", "SG1B001", "SG1B002");
    net.add_global_controller(agc);
    bus = net.a_Bus{2};
    comp = bus.a_Component{1};
end


function id = error_id(fh)
% 実行してエラー ID を返す (エラーにならなければ "")
    id = "";
    try
        DebugScript.helper.quiet(fh);
    catch ME
        id = string(ME.identifier);
    end
end
