% F21 LocalController の接続時の検査 (Issue #98) と取り外し (Issue #103)
%
%   未知の key と、接続先の入力に一致しない出力名は add_local_controller で止まり、機器は変わらない
%   入力名の誤りは検出しない (意図した未接続と同じ形。validate で確認する)
%   remove_local_controller はタグで外す。PSS の残った AVR は RemoveNested=true がなければエラー
%
% 実行: runtests("DebugScript.test_F21_controller_editing")  または  DebugScript.run_all("Features","F21")

% 共通設定 (各テストの前に毎回実行される)
str_key = "GUILDA:Component:InvalidControllerKey";
str_out = "GUILDA:Component:ControllerOutput";


%% An unknown key stops with an error instead of attaching nothing
[net, gen] = fresh_network();
ME = caught(@() gen.add_local_controller(DebugScript.helper.OutputStub("governor", "Pmech")));
assert(ME.identifier == str_key)
assert(contains(ME.message, "governor") && contains(ME.message, "avr") && contains(ME.message, "local"))
assert(isempty(gen.a_LocalController))


%% An output matching no input stops with an error naming the output and the inputs
[net, gen] = fresh_network();
ME = caught(@() gen.add_local_controller(DebugScript.helper.OutputStub("avr", "Vfiled")));
assert(ME.identifier == str_out)
assert(contains(ME.message, "Vfiled") && contains(ME.message, gen.str_tag))
assert(contains(ME.message, "Pmech") && contains(ME.message, "Vfield"))
assert(isempty(gen.a_LocalController))


%% An AVR on a load stops with an error
net = DebugScript.helper.build_ieee14();
comp = net.a_Bus{9}.a_Component{1};
assert(isa(comp, "component.load.impedance") || isa(comp, "component.load.power"))
avr = controller.avr.AVR_ST1("avr1");
assert(caught(@() comp.add_local_controller(avr)).identifier == str_out)
assert(isempty(comp.a_LocalController) && isempty(avr.a_Component))


%% A PSS output must match an input of the AVR it goes under
[net, gen] = fresh_network();
avr = controller.avr.AVR_ST1("avr1");
gen.add_local_controller(avr);
ME = caught(@() gen.add_local_controller(DebugScript.helper.OutputStub("pss", "Vpsss")));
assert(ME.identifier == str_out && contains(ME.message, avr.str_tag) && contains(ME.message, "Vpss"))
assert(isempty(avr.a_LocalController))


%% A PSS given with a new AVR is checked against the new AVR, before anything changes
[net, gen] = fresh_network();
old = controller.avr.AVR_ST1("avrOld");
gen.add_local_controller(old);
DebugScript.helper.quiet(@() net.initialize);
n_log = height(net.tab_editLog);
avrIn = controller.avr.AVR_ST1("avrNew");
ME = caught(@() gen.add_local_controller(avrIn, DebugScript.helper.OutputStub("pss", "Vfield")));
assert(ME.identifier == str_out && contains(ME.message, avrIn.str_tag))
assert(gen.a_LocalController{1} == old && isempty(avrIn.a_Component))
assert(~net.s_edit.l_staleEquilibrium && height(net.tab_editLog) == n_log)


%% A PSS without an AVR keeps its own error
[net, gen] = fresh_network();
ME = caught(@() gen.add_local_controller(controller.pss.PSS1("pss1")));
assert(contains(ME.message, "no AVR"))
assert(ME.identifier ~= str_out)


%% An LQR driving an unknown input stops with the same error
[net, gen] = fresh_network();
lqr = controller.local_LQR("lqr1", Input="Vref");
assert(caught(@() gen.add_local_controller(lqr)).identifier == str_out)
assert(isempty(gen.a_LocalController) && isempty(lqr.a_Component))


%% Valid controllers still attach
[net, gen] = fresh_network();
avr = controller.avr.AVR_ST1("avr1");
pss = controller.pss.PSS1("pss1");
gen.add_local_controller(avr, pss);
assert(gen.a_LocalController{1} == avr && avr.a_LocalController{1} == pss)

% PSS を既存の AVR の下へ
[net, gen] = fresh_network();
avr = controller.avr.AVR_ST1("avr1");
gen.add_local_controller(avr);
pss = controller.pss.PSS1("pss1");
gen.add_local_controller(pss);
assert(avr.a_LocalController{1} == pss)

% 既定の LQR の出力は接続時に機器の全入力になり、選んだ入力も通る
[net, gen] = fresh_network();
lqr = controller.local_LQR("lqr1");
gen.add_local_controller(lqr);
assert(isequal(lqr.sv_y, gen.sv_u))
[net, gen] = fresh_network();
lqr = controller.local_LQR("lqr2", Input="Vfield");
gen.add_local_controller(lqr);
assert(lqr.sv_y == "Vfield")


%% A misspelled input is not an error
[net, gen] = fresh_network();
con = DebugScript.helper.ObserveStub("omegaa");
gen.add_local_controller(con);
assert(con.iv_obsY == 0 && con.iv_obsX == 0)


%% remove_local_controller: the PSS alone, then the AVR, each logged and leaving a working model
[net, gen] = fresh_network();
DebugScript.helper.quiet(@() net.initialize);
n0 = numel(gen.rv_Xequilibrium_all);
nx0 = size(net.get_sys().A,1);
avr = controller.avr.AVR_ST1("avr1");
pss = controller.pss.PSS1("pss1");
gen.add_local_controller(avr, pss);
DebugScript.helper.quiet(@() net.initialize);
assert(numel(gen.rv_Xequilibrium_all) == n0 + numel(avr.sv_x) + numel(pss.sv_x))

gen.remove_local_controller(pss.str_tag);
assert(net.s_edit.l_staleEquilibrium && net.tab_editLog.tag(end) == "Topology")
assert(gen.a_LocalController{1} == avr && isempty(avr.a_LocalController) && isempty(pss.a_Component))
DebugScript.helper.quiet(@() net.initialize);
assert(numel(gen.rv_Xequilibrium_all) == n0 + numel(avr.sv_x))

gen.remove_local_controller(avr.str_tag);
assert(net.s_edit.l_staleEquilibrium && net.tab_editLog.tag(end) == "Topology")
assert(isempty(gen.a_LocalController) && isempty(avr.a_Component))
DebugScript.helper.quiet(@() net.initialize);
assert(numel(gen.rv_Xequilibrium_all) == n0)
assert(size(net.get_sys().A,1) == nx0)
sol = net.simulate([0,1], DebugScript.helper.noop_event(net,[0,1]));
assert(sol.flag == 1)


%% remove_local_controller: an AVR that has a PSS is rejected unless RemoveNested is true
[net, gen] = fresh_network();
avr = controller.avr.AVR_ST1("avr1");
pss = controller.pss.PSS1("pss1");
gen.add_local_controller(avr, pss);
DebugScript.helper.quiet(@() net.initialize);
n_log = height(net.tab_editLog);
ME = caught(@() gen.remove_local_controller(avr.str_tag));
assert(ME.identifier == "GUILDA:Component:ControllerHasNested" && contains(ME.message, "pss1"))
assert(gen.a_LocalController{1} == avr && avr.a_LocalController{1} == pss && pss.a_Component == avr)
assert(~net.s_edit.l_staleEquilibrium && height(net.tab_editLog) == n_log)

gen.remove_local_controller(avr.str_tag, RemoveNested=true);
assert(isempty(gen.a_LocalController) && isempty(avr.a_LocalController))
assert(isempty(avr.a_Component) && isempty(pss.a_Component))
assert(height(net.tab_editLog) == n_log + 1 && contains(net.tab_editLog.log(end), "pss1"))


%% remove_local_controller: an unknown tag changes nothing
[net, gen] = fresh_network();
assert(caught(@() gen.remove_local_controller("none")).identifier == "GUILDA:Component:ControllerNotFound")
avr = controller.avr.AVR_ST1("avr1");
gen.add_local_controller(avr);
DebugScript.helper.quiet(@() net.initialize);
ME = caught(@() gen.remove_local_controller("none"));
assert(ME.identifier == "GUILDA:Component:ControllerNotFound" && contains(ME.message, "none") && contains(ME.message, gen.str_tag))
assert(gen.a_LocalController{1} == avr && ~net.s_edit.l_staleEquilibrium)


%% remove_local_controller: removed controllers can be attached again, here or elsewhere
[net, gen] = fresh_network();
avr = controller.avr.AVR_ST1("avr1");
pss = controller.pss.PSS1("pss1");
gen.add_local_controller(avr, pss);
gen.remove_local_controller(avr.str_tag, RemoveNested=true);
gen2 = net.a_Bus{2}.a_Component{1};
gen2.add_local_controller(avr, pss);
assert(gen2.a_LocalController{1} == avr && avr.a_LocalController{1} == pss && pss.a_Component == avr)
lqr = controller.local_LQR("lqr1");
gen.add_local_controller(lqr);
DebugScript.helper.quiet(@() net.initialize);
gen.remove_local_controller(lqr.str_tag);
assert(isempty(gen.a_LocalController) && isempty(lqr.a_Component))


function [net, gen] = fresh_network()
    % A new network for each test, so that the controllers of a test do not reach the next
    net = DebugScript.helper.build_ieee14();
    gen = net.a_Bus{1}.a_Component{1};
end

function ME = caught(fcn)
    % Run fcn, which must stop with an error, and return the error
    ME = [];
    try
        fcn();
    catch ME
    end
    assert(~isempty(ME), "No error was raised.")
    ME = struct("identifier", string(ME.identifier), "message", string(ME.message));
end
