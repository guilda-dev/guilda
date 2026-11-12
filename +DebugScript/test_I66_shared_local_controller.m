% I66 1 つの LocalController を複数の機器へ接続できないことの確認 (Issue #66)
%
%   制御器は add_local_controller がキーから毎回作るため、別の機器に付いた制御器を付け直すことはできない
%   (以前の SharedController の検査は不要になった)。ここでは差し替えで外れた制御器が
%   削除されること (無効なハンドル)、PSS が新しい AVR へ移ることを確かめる
%
% 実行: runtests("DebugScript.test_I66_shared_local_controller")  または  DebugScript.run_all("Features","I66")


%% A replaced AVR is deleted
[net, gen1, gen2] = fresh_network();
old = gen1.add_local_controller("avr-ST1");
new = quiet_replace(@() gen1.add_local_controller("avr-DC1"));
assert(~isvalid(old))
assert(new.a_Component == gen1 && gen1.a_LocalController{1} == new)


%% Replacing the AVR moves its PSS to the new AVR
[net, gen1, gen2] = fresh_network();
avr1 = gen1.add_local_controller("avr-ST1");
pss  = gen1.add_local_controller("pss-PSS1");
avr2 = quiet_replace(@() gen1.add_local_controller("avr-DC1"));
assert(pss.a_Component == avr2 && avr2.a_LocalController{1} == pss)
assert(~isvalid(avr1))


%% A PSS is deleted with its AVR when a local controller replaces the AVR
[net, gen1, gen2] = fresh_network();
gen1.add_local_controller("avr-ST1");
pss = gen1.add_local_controller("pss-PSS1");
quiet_replace(@() gen1.add_local_controller("local-LQR"));
assert(~isvalid(pss))


%% A PSS without an AVR still reports the missing AVR
[net, gen1, gen2] = fresh_network();
assert(contains(caught(@() gen2.add_local_controller("pss-PSS1")).message, "no AVR"))


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
    ME = struct("identifier", string(DebugScript.helper.msg_id(ME)), "message", string(ME.message));
end

function con = quiet_replace(fcn)
    % Run a replacement, which issues the ReplaceController warning, and return the new controller
    sct_warn = warning("off", "GUILDA:Component:ReplaceController");
    c_warn = onCleanup(@() warning(sct_warn));
    con = fcn();
end
