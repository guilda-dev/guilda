% I57 大域制御器が参照する機器の削除と差し替え
%
% 制御対象の remove_component / replace_component が拒否されることを確認する。
%
% 実行: runtests("DebugScript.test_I57_stale_gc_references")  または  DebugScript.run_all("Features","I57")

c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% remove_component rejects a controlled component and changes nothing
[net, agc, bus, comp] = build_controlled_network();
assert(error_id(@() bus.remove_component("B002SG1")) == "GUILDA:Bus:ComponentControlled")
assert(bus.a_Component{1} == comp && comp.a_Bus == bus)


%% replace_component rejects a controlled component and changes nothing
[net, agc, bus, comp] = build_controlled_network();
assert(error_id(@() bus.replace_component("B002SG1", "gen-classical")) == "GUILDA:Bus:ComponentControlled")
assert(bus.a_Component{1} == comp && comp.a_Bus == bus)


%% The component can be edited after removing the global controller
[net, agc, bus, comp] = build_controlled_network();
net.remove_global_controller(agc.s_tag);
bus.replace_component("B002SG1", "gen-classical");
bus.remove_component("B002SG1");
assert(~ismember("B002SG1", string(bus.a_Component)))


%% A component no controller controls can still be edited
[net, agc, bus, comp] = build_controlled_network();
bus3 = net.a_Bus{3};
s_tag = string(bus3.a_Component{1});
new = bus3.replace_component(s_tag, "gen-classical");
assert(bus3.a_Component{1} == new)
bus3.remove_component(s_tag);
assert(~ismember(s_tag, string(bus3.a_Component)))


%% A correct controller still simulates
[net, agc, bus, comp] = build_controlled_network();
DebugScript.helper.quiet(@() net.initialize);
[~, flag] = DebugScript.helper.quiet(@() net.simulate([0,0.1]));
assert(flag == 1)


function [net, agc, bus, comp] = build_controlled_network()
% AGC が B001SG1, B002SG1 を制御する IEEE14 (bus は B002SG1 の母線、comp はその発電機)
    net = DebugScript.helper.build_ieee14();
    DebugScript.helper.quiet(@() net.initialize);
    agc = net.add_global_controller("agc-PI", ["B001SG1","B002SG1"]);
    bus = net.a_Bus{2};
    comp = bus.a_Component{1};
end


function id = error_id(fh)
% 実行してエラー ID を返す (エラーにならなければ "")
    id = "";
    try
        DebugScript.helper.quiet(fh);
    catch ME
        id = string(DebugScript.helper.msg_id(ME));
    end
end
