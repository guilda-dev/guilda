% F21 LocalController の接続時の検査 (Issue #98) と取り外し (Issue #103)
%
%   未知の役割 (s_role) と、接続先の入力に一致しない出力名は add_local_controller で止まり、機器は変わらない
%   入力名の誤りは検出しない (意図した未接続と同じ形。validate で確認する)
%   remove_local_controller はタグで外す。PSS の残った AVR は RemoveNested=true がなければエラー
%
% 実行: runtests("DebugScript.test_F21_controller_editing")  または  DebugScript.run_all("Features","F21")

% 共通設定 (各テストの前に毎回実行される)
s_key   = "GUILDA:Component:InvalidControllerKey";
s_out   = "GUILDA:Component:ControllerOutput";


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% An unknown role stops with an error instead of attaching nothing
[s_stub, c] = stub("turbine");
[net, gen] = fresh_network();
ME = caught(@() gen.add_local_controller(s_stub, parameter=struct(Output="Pmech")));
assert(DebugScript.helper.msg_id(ME) == s_key)
assert(contains(ME.message, "turbine") && contains(ME.message, "avr") && contains(ME.message, "governor"))
assert(isempty(gen.a_LocalController))


%% An output matching no input stops with an error naming the output and the inputs
[s_stub, c] = stub("avr");
[net, gen] = fresh_network();
ME = caught(@() gen.add_local_controller(s_stub, parameter=struct(Output="Vfiled")));
assert(DebugScript.helper.msg_id(ME) == s_out)
assert(contains(ME.message, "Vfiled") && contains(ME.message, gen.s_tag))
assert(contains(ME.message, "Pmech") && contains(ME.message, "Vfield"))
assert(isempty(gen.a_LocalController))


%% An AVR on a load stops with an error
net = DebugScript.helper.build_ieee14();
comp = net.a_Bus{9}.a_Component{1};
assert(isa(comp, "component.load.impedance") || isa(comp, "component.load.power"))
assert(DebugScript.helper.msg_id(caught(@() comp.add_local_controller("avr-ST1"))) == s_out)
assert(isempty(comp.a_LocalController))


%% A PSS output must match an input of the AVR it goes under
[s_stub, c] = stub("pss");
[net, gen] = fresh_network();
avr = gen.add_local_controller("avr-ST1");
ME = caught(@() gen.add_local_controller(s_stub, parameter=struct(Output="Vpsss")));
assert(DebugScript.helper.msg_id(ME) == s_out && contains(ME.message, avr.s_tag) && contains(ME.message, "Vpss"))
assert(isempty(avr.a_LocalController))


%% A PSS is checked against the AVR it goes under, before anything changes
[s_stub, c] = stub("pss");
[net, gen] = fresh_network();
avr = gen.add_local_controller("avr-ST1");
DebugScript.helper.quiet(@() net.initialize);
sv_log = DebugScript.helper.stale(net);
ME = caught(@() gen.add_local_controller(s_stub, parameter=struct(Output="Vfield")));
assert(DebugScript.helper.msg_id(ME) == s_out && contains(ME.message, avr.s_tag))
assert(gen.a_LocalController{1} == avr && isempty(avr.a_LocalController))
assert(~DebugScript.helper.is_stale(net) && isequal(DebugScript.helper.stale(net), sv_log))


%% A PSS without an AVR keeps its own error
[net, gen] = fresh_network();
ME = caught(@() gen.add_local_controller("pss-PSS1"));
assert(contains(ME.message, "no AVR"))
assert(DebugScript.helper.msg_id(ME) ~= s_out)


%% An LQR driving an unknown input stops with the same error
[net, gen] = fresh_network();
assert(DebugScript.helper.msg_id(caught(@() gen.add_local_controller("local-LQR", parameter=struct(Input="Vref")))) == s_out)
assert(isempty(gen.a_LocalController))


%% Valid controllers still attach
[net, gen] = fresh_network();
avr = gen.add_local_controller("avr-ST1");
pss = gen.add_local_controller("pss-PSS1");
assert(gen.a_LocalController{1} == avr && avr.a_LocalController{1} == pss)
assert(avr.s_tag == gen.s_tag + "CA1" && pss.s_tag == gen.s_tag + "CP2")

% 既定の LQR の出力は接続時に機器の全入力になり、選んだ入力も通る
[net, gen] = fresh_network();
lqr = gen.add_local_controller("local-LQR");
assert(isequal(lqr.sv_y, gen.sv_u))
[net, gen] = fresh_network();
lqr = gen.add_local_controller("local-LQR", parameter=struct(Input="Vfield"));
assert(lqr.sv_y == "Vfield")


%% A misspelled input is not an error
[s_stub, c] = stub("local");
[net, gen] = fresh_network();
con = gen.add_local_controller(s_stub, parameter=struct(Input="omegaa"));
assert(con.iv_obsY == 0 && con.iv_obsX == 0)


%% remove_local_controller: the PSS alone, then the AVR, each logged and leaving a working model
[net, gen] = fresh_network();
DebugScript.helper.quiet(@() net.initialize);
n0 = numel(gen.rv_Xequilibrium_all);
nx0 = size(net.get_sys().A,1);
avr = gen.add_local_controller("avr-ST1");
pss = gen.add_local_controller("pss-PSS1");
DebugScript.helper.quiet(@() net.initialize);
assert(numel(gen.rv_Xequilibrium_all) == n0 + numel(avr.sv_x) + numel(pss.sv_x))

gen.remove_local_controller(pss.s_tag);
assert(DebugScript.helper.is_stale(net) && any(contains(gen.sct_stale.equilibrium, "---remove->>")))
assert(gen.a_LocalController{1} == avr && isempty(avr.a_LocalController) && ~isvalid(pss))
DebugScript.helper.quiet(@() net.initialize);
assert(numel(gen.rv_Xequilibrium_all) == n0 + numel(avr.sv_x))

gen.remove_local_controller(avr.s_tag);
assert(DebugScript.helper.is_stale(net) && any(contains(gen.sct_stale.equilibrium, "---remove->>")))
assert(isempty(gen.a_LocalController) && ~isvalid(avr))
DebugScript.helper.quiet(@() net.initialize);
assert(numel(gen.rv_Xequilibrium_all) == n0)
assert(size(net.get_sys().A,1) == nx0)
sol = net.simulate(DebugScript.helper.noop_event(net,[0,1]).s_tag, Time=[0,1]);
assert(sol.flag == 1)


%% remove_local_controller: an AVR that has a PSS is rejected unless RemoveNested is true
[net, gen] = fresh_network();
avr = gen.add_local_controller("avr-ST1");
pss = gen.add_local_controller("pss-PSS1");
DebugScript.helper.quiet(@() net.initialize);
sv_log = DebugScript.helper.stale(net);
ME = caught(@() gen.remove_local_controller(avr.s_tag));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:Component:ControllerHasNested" && contains(ME.message, pss.s_tag))
assert(gen.a_LocalController{1} == avr && avr.a_LocalController{1} == pss && pss.a_Component == avr)
assert(~DebugScript.helper.is_stale(net) && isequal(DebugScript.helper.stale(net), sv_log))

s_pss = pss.s_tag;
gen.remove_local_controller(avr.s_tag, RemoveNested=true);
assert(isempty(gen.a_LocalController) && ~isvalid(avr) && ~isvalid(pss))
assert(numel(gen.sct_stale.equilibrium) == 1 && contains(gen.sct_stale.equilibrium, s_pss))


%% remove_local_controller: an unknown tag changes nothing
[net, gen] = fresh_network();
assert(DebugScript.helper.msg_id(caught(@() gen.remove_local_controller("none"))) == "GUILDA:Component:ControllerNotFound")
avr = gen.add_local_controller("avr-ST1");
DebugScript.helper.quiet(@() net.initialize);
ME = caught(@() gen.remove_local_controller("none"));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:Component:ControllerNotFound" && contains(ME.message, "none") && contains(ME.message, gen.s_tag))
assert(gen.a_LocalController{1} == avr && ~DebugScript.helper.is_stale(net))


%% remove_local_controller: a removed LQR leaves the component without controllers
[net, gen] = fresh_network();
lqr = gen.add_local_controller("local-LQR");
DebugScript.helper.quiet(@() net.initialize);
gen.remove_local_controller(lqr.s_tag);
assert(isempty(gen.a_LocalController) && ~isvalid(lqr))


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
    ME = struct("identifier", string(DebugScript.helper.msg_id(ME)), "message", string(ME.message));
end

function [s_key, c] = stub(s_role)
    % DebugScript.helper.ObserveStub を役割 s_role のキーとして登録する (c が消えると登録を取り消す)
    s_class = "controller.test_observe_" + s_role;
    s_key   = "test-observe-" + s_role;
    c = DebugScript.helper.register_stub("ObserveStub", s_class, Replace=["s_role = ""local""", "s_role = """ + s_role + """"]);
end
