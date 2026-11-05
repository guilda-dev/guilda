% Issue 93: 返した平衡点でモデルを評価して initialize で報告する
%
% get_equilibrium の誤りは initialize を通り、状態が外乱なしで動いていた。大きさの誤りは
% simulate で一般的なエラーになっていた。残差は警告、大きさの誤りはエラーにする。
%
% 実行: runtests("DebugScript.test_I93_model_equilibrium")  または  DebugScript.run_all("Features","I93")

s_warn = "GUILDA:PowerNetwork:EquilibriumResidual";


%% Models of components are checked with every Method
% スタブをキーとして一時的に登録するので、GUILDA の再実行が 1 回で済むようにまとめる
c_stub = register_stub();

% 残差は警告で、タグと値を示し、系統は使える
net = network_with("equilibrium");
[s_id, s_msg] = warning_of(@() net.initialize);
assert(s_id == s_warn, s_id)
assert(contains(s_msg, "|dx| = 0.1") && contains(s_msg, "'" + string(stub(net)) + "'"), s_msg)
assert(~net.l_staleEquilibrium)
DebugScript.helper.quiet(@() net.simulate([0 0.1]));

% 誤りのない機器は警告しない
net = network_with("none");
assert(warning_of(@() net.initialize) == "")

% 警告は止められる
net = network_with("equilibrium");
sct_warn = warning("off", "all");   % ID がないので個別には止められない
c_warn = onCleanup(@() warning(sct_warn));
s_out = evalc("net.initialize;");
assert(~contains(s_out, "do not hold"), s_out)
clear c_warn

% Method="equilibrium" は計算し直した状態を調べる
net = network_with("none");
assert(warning_of(@() net.initialize) == "")
comp = stub(net);
comp.para_dynamics.bad = find(comp.sr_bad == "equilibrium");
assert(warning_of(@() net.initialize(Method="equilibrium")) == s_warn)

% Method="OPF" も調べる
net = network_with("equilibrium");
assert(warning_of(@() net.initialize(Method="OPF")) == s_warn)

% 契約違反はタグを示して止まり、平衡点は古いままになる
c_case = ["xsize","InitializeEquilibriumSize","x has 3 elements (2 expected)"; ...
          "currentreal","InitializeModelSize","fcn_I"; ...
          "dxsize","InitializeModelSize","fcn_dx"; ...
          "dxerror","InitializeModelFailed","stub stopped"];
for k = 1:height(c_case)
    net = network_with(c_case(k,1));
    check_stop(net, c_case(k,2), ["'" + string(stub(net)) + "'", c_case(k,3)]);
end

% 島の警告を隠さない
net = network_with("equilibrium");
net.add_bus("V",1);
net.add_bus();
net.add_branch("pi",[4,5], "R",0, "X",0.1);
net.a_Bus{4}.add_component("gen-park", "P",0.5, "Q",nan);
net.a_Bus{5}.add_component("load-power", "P",-0.5, "Q",-0.1);
s_out = evalc("net.initialize;");
assert(all(contains(s_out, ["do not hold", "split into"])), s_out)
clear c_stub


%% Residuals of a local controller name the controller
c_case = ["residual","'CLbad': |dx| = 0.1"; "input","'CLbad': |dx| = 0.2"];
for k = 1:height(c_case)
    net = network_with_controller(c_case(k,1));
    [s_id, s_msg] = warning_of(@() net.initialize);
    assert(s_id == s_warn, s_id)
    assert(contains(s_msg, c_case(k,2)), s_msg)
end


%% An output that does not match the input it drives names the component
[net, comp] = network_with_controller("output");
[s_id, s_msg] = warning_of(@() net.initialize);
assert(s_id == s_warn, s_id)
assert(contains(s_msg, "'" + comp.s_tag + "'") && contains(s_msg, "|u - source| = 0.1"), s_msg)


%% A wrong state size of a local controller stops with its tag
net = network_with_controller("xsize");
check_stop(net, "InitializeEquilibriumSize", ["'CLbad'", "x has 2 elements (1 expected)"]);


%% A controller under an AVR is checked
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
comp.add_local_controller(controller.avr.AVR_ST1("avr1"), DebugScript.helper.BadPSSStub("bad"));
check_stop(net, "InitializeEquilibriumSize", "'CPbad'");


%% A global controller is checked
[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
net.add_global_controller(DebugScript.helper.BadAGCStub(net, "agc", "output", comp));
[s_id, s_msg] = warning_of(@() net.initialize);
assert(s_id == s_warn, s_id)
assert(contains(s_msg, "'agc'"), s_msg)

[net, comp] = DebugScript.helper.build_3bus("gen-1axis");
net.add_global_controller(DebugScript.helper.BadAGCStub(net, "agc", "xsize", comp));
check_stop(net, "InitializeEquilibriumSize", "'agc'");


%% The built-in networks are far below the threshold, with their controllers
for s_net = ["IEEE9bus","IEEE14bus","IEEE14bus_lossless","IEEE14bus_NoTap","IEEE68bus", ...
               "Ishizaki6Bus","TEST31bus","Txt3Bus","Tutorial3bus", ...
               "IEEJ_EAST10","IEEJ_EAST30","IEEJ_WEST10","IEEJ_WEST30"]
    net = network.(s_net)();
    s_out = evalc("net.initialize;");
    assert(~contains(s_out, "do not hold"), s_net)
end

net = network.IEEE14bus();
g1 = net.a_Bus{1}.a_Component{1};
g2 = net.a_Bus{2}.a_Component{1};
g1.add_local_controller(controller.avr.AVR_ST1("avr1"), controller.pss.PSS1("pss1"));
g2.add_local_controller(controller.local_LQR("lqr1"));
net.add_global_controller(controller.agc.broadcast_PI_AGC(net, "agc", g1, g2, alpha=[1;1], beta=[1;1], kP=100, kI=500));
s_out = evalc("net.initialize;");
assert(~contains(s_out, "do not hold"), s_out)


% ---- local functions ----
function c = register_stub()
% BadComponentStub の写しを add_component のキーにする (+DebugScript のクラスとその子は登録されない)
    s_file = fullfile(fileparts(fileparts(which("component.load.power"))), "bad_i93_stub.m");
    str = fileread(which("DebugScript.helper.BadComponentStub"));
    str = replace(str, "DebugScript.helper.BadComponentStub", "component.load.bad_i93_stub");
    str = replace(str, "classdef BadComponentStub", "classdef bad_i93_stub");
    str = replace(str, "BadComponentStub(s_bad, s_tag, opt)", "bad_i93_stub(s_tag, s_bad, opt)");
    str = regexprep(str, '(\n\s+)s_bad(\s+%[^\n]*)(\n\s+)s_tag = "1"(\s+%[^\n]*)', '$1s_tag$4$3s_bad$2');
    writelines(str, s_file);
    rehash
    evalc("GUILDA;");
    c = onCleanup(@() unregister_stub(s_file));
end

function unregister_stub(s_file)
    delete(s_file);
    rehash
    evalc("GUILDA;");
end

function net = network_with(s_bad)
    net = DebugScript.helper.build_3bus("gen-1axis");
    net.a_Bus{3}.add_component("test-bad-stub", "parameter",s_bad);
end

function comp = stub(net)
    comp = net.a_Bus{3}.a_Component{2};
end

function [net, comp] = network_with_controller(s_bad)
    [net, comp] = DebugScript.helper.build_3bus("gen-1axis");
    comp.add_local_controller(DebugScript.helper.BadControllerStub(s_bad));
end

function check_stop(net, s_id, sv_text)
    ME = [];
    try
        DebugScript.helper.quiet(@() net.initialize);
    catch ME
    end
    assert(~isempty(ME), "initialize did not stop")
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:PowerNetwork:" + s_id, DebugScript.helper.msg_id(ME))
    assert(all(contains(ME.message, sv_text)), ME.message)
    assert(net.l_staleEquilibrium)
end

function [s_id, s_msg] = warning_of(fcn)
% 関数を実行し、最後の警告の ID と文を返す (なければ "")
    lastwarn("", "");
    evalc("fcn();");
    [s_msg, s_id] = lastwarn(); s_id = DebugScript.helper.msg_id(s_msg, s_id);
    s_msg   = string(s_msg);
    s_id    = string(s_id);
end
