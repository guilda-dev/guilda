% I66 1 つの LocalController を複数の機器へ接続できないことの確認 (Issue #66)
%
%   別の親を持つ AVR / PSS / local の接続は原因を示すエラーになり、機器の状態は変わらない
%   切り離された LocalController の再接続と、同じ機器での正規の差し替えは動く
%
% 実行: runtests("DebugScript.test_I66_shared_local_controller")  または  DebugScript.run_all("Features","I66")

% 共通設定 (各テストの前に毎回実行される)
str_id = "GUILDA:Component:SharedController";


%% A second connection of an AVR stops with an error naming the cause
[net, gen1, gen2] = fresh_network();
avr = controller.avr.AVR_ST1("avrA");
gen1.add_local_controller(avr);
ME = caught(@() gen2.add_local_controller(avr));
assert(ME.identifier == str_id)
assert(contains(ME.message, "avrA") && contains(ME.message, gen1.str_tag) && contains(ME.message, gen2.str_tag))
assert(avr.a_Component == gen1 && gen1.a_LocalController{1} == avr)
assert(isempty(gen2.a_LocalController))


%% A second connection of a local controller stops with an error
[net, gen1, gen2] = fresh_network();
lqr = controller.local_LQR("lqrA");
gen1.add_local_controller(lqr);
assert(caught(@() gen2.add_local_controller(lqr)).identifier == str_id)
assert(lqr.a_Component == gen1 && isempty(gen2.a_LocalController))


%% A PSS under the AVR of another component stops with an error
[net, gen1, gen2] = fresh_network();
avr1 = controller.avr.AVR_ST1("avr1");
avr2 = controller.avr.AVR_ST1("avr2");
pss  = controller.pss.PSS1("pss1");
gen1.add_local_controller(avr1, pss);
gen2.add_local_controller(avr2);
assert(caught(@() gen2.add_local_controller(pss)).identifier == str_id)
assert(pss.a_Component == avr1 && avr1.a_LocalController{1} == pss)
assert(isempty(avr2.a_LocalController))


%% A rejected call changes nothing, even when an earlier argument is valid
[net, gen1, gen2] = fresh_network();
avr1  = controller.avr.AVR_ST1("avr1");
avr2  = controller.avr.AVR_ST1("avr2");
avrIn = controller.avr.AVR_ST1("avrNew");
pss   = controller.pss.PSS1("pss1");
gen1.add_local_controller(avr1, pss);
gen2.add_local_controller(avr2);
assert(caught(@() gen2.add_local_controller(avrIn, pss)).identifier == str_id)
assert(gen2.a_LocalController{1} == avr2 && avr2.a_Component == gen2)
assert(isempty(avrIn.a_Component))
assert(pss.a_Component == avr1)


%% The equilibrium of the network does not go stale on a rejected connection
[net, gen1, gen2] = fresh_network();
avr = controller.avr.AVR_ST1("avrA");
gen1.add_local_controller(avr);
DebugScript.helper.quiet(@() net.initialize);
n_log = height(net.tab_editLog);
assert(caught(@() gen2.add_local_controller(avr)).identifier == str_id)
assert(~net.s_edit.l_staleEquilibrium && height(net.tab_editLog) == n_log)


%% A replaced AVR is detached and can be attached to another component
[net, gen1, gen2] = fresh_network();
old = controller.avr.AVR_ST1("avrOld");
gen1.add_local_controller(old);
quiet_replace(@() gen1.add_local_controller(controller.avr.AVR_DC1("avrNew")));
assert(isempty(old.a_Component))
gen2.add_local_controller(old);
assert(old.a_Component == gen2 && gen2.a_LocalController{1} == old)


%% Replacing the AVR moves its PSS to the new AVR
[net, gen1, gen2] = fresh_network();
avr1 = controller.avr.AVR_ST1("avr1");
avr2 = controller.avr.AVR_DC1("avr2");
pss  = controller.pss.PSS1("pss1");
gen1.add_local_controller(avr1, pss);
quiet_replace(@() gen1.add_local_controller(avr2));
assert(pss.a_Component == avr2 && avr2.a_LocalController{1} == pss)
assert(isempty(avr1.a_LocalController))


%% The PSS of the replaced AVR can be given again in the same call
[net, gen1, gen2] = fresh_network();
avr1 = controller.avr.AVR_ST1("avr1");
avr2 = controller.avr.AVR_DC1("avr2");
pss  = controller.pss.PSS1("pss1");
gen1.add_local_controller(avr1, pss);
quiet_replace(@() gen1.add_local_controller(avr2, pss));
assert(pss.a_Component == avr2 && avr2.a_LocalController{1} == pss)


%% Attaching the same controllers to their own component again still works
[net, gen1, gen2] = fresh_network();
avr = controller.avr.AVR_ST1("avr1");
pss = controller.pss.PSS1("pss1");
gen1.add_local_controller(avr, pss);
gen1.add_local_controller(pss);
assert(pss.a_Component == avr && avr.a_LocalController{1} == pss)
quiet_replace(@() gen1.add_local_controller(avr));
assert(avr.a_Component == gen1 && gen1.a_LocalController{1} == avr)
assert(pss.a_Component == avr && avr.a_LocalController{1} == pss)


%% A PSS detached with its AVR can be attached to another component
[net, gen1, gen2] = fresh_network();
pss = controller.pss.PSS1("pss1");
gen1.add_local_controller(controller.avr.AVR_ST1("avr1"), pss);
quiet_replace(@() gen1.add_local_controller(controller.local_LQR("lqr1")));
assert(isempty(pss.a_Component))
gen2.add_local_controller(controller.avr.AVR_ST1("avr2"), pss);
assert(pss.a_Component == gen2.a_LocalController{1})


%% A PSS without an AVR still reports the missing AVR
[net, gen1, gen2] = fresh_network();
pss = controller.pss.PSS1("pss1");
assert(contains(caught(@() gen2.add_local_controller(pss)).message, "no AVR"))


function [net, gen1, gen2] = fresh_network()
    % A new network for each test, so that the controllers of a test do not reach the next
    net  = DebugScript.helper.build_ieee14();
    gen1 = net.a_Bus{1}.a_Component{1};
    gen2 = net.a_Bus{2}.a_Component{1};
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

function quiet_replace(fcn)
    % Run a replacement, which issues the ReplaceController warning
    s_warn = warning("off", "GUILDA:Component:ReplaceController");
    c_warn = onCleanup(@() warning(s_warn));
    fcn();
end
