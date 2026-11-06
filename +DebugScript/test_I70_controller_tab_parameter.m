% I70 制御器の tab_parameter への代入 (Issue #70)
%
% LocalController と GlobalController でも Component と同じ形
% (ctrl.tab_parameter.dynamics.<name> = ...) でパラメータを編集でき、編集検知が働く。
%
% 実行: runtests("DebugScript.test_I70_controller_tab_parameter")
%       または  DebugScript.run_all("Features","I70")


%% Local controller tab_parameter edit is logged and rebuilt
net = DebugScript.helper.build_ieee14();
comp = net.a_Bus{1}.a_Component{1};
comp.add_local_controller("avr-ST1");
avr = comp.a_LocalController{1};
DebugScript.helper.quiet(@() net.initialize);
h_dx = avr.f_dx;

val = 2 * avr.tab_parameter.dynamics.kap;
avr.tab_parameter.dynamics.kap = val;
assert(avr.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", avr.a_Parameter)}.tab_parameter.kap == val && avr.tab_parameter.dynamics.kap == val)
assert(isequal(h_dx, avr.f_dx) && DebugScript.helper.is_stale(net))   % initialize で作り直す
sv = DebugScript.helper.stale(net);
assert(numel(sv) == 1 && contains(sv, "edit kap: "))   % 他の列は変更扱いにならない
assert(isequal(avr.sct_stale.equilibrium, sv) && isequal(avr.sct_stale.odefcn, sv))

DebugScript.helper.quiet(@() net.initialize);
assert(~isequal(h_dx, avr.f_dx))
x = avr.rv_Xequilibrium + 0.01;  u = avr.rv_Uequilibrium;
V = [real(comp.c_Vequilibrium); imag(comp.c_Vequilibrium)];
para = avr.tab_parameter.dynamics{:, avr.sv_para}.';
assert(norm(avr.f_dx(0,x,V,[0;0],u) - avr.fcn_dx(0,x,V,[0;0],u,para,60)) < 1e-12, ...
       "AVR の f_dx が変更前の定数を使っている")


%% Nested local controller tab_parameter edit is logged
net = DebugScript.helper.build_ieee14();
comp = net.a_Bus{1}.a_Component{1};
comp.add_local_controller("avr-ST1");
comp.add_local_controller("pss-PSS1");
pss = comp.a_LocalController{1}.a_LocalController{1};
DebugScript.helper.quiet(@() net.initialize);

name = pss.sv_para(1);
val  = 2 * pss.tab_parameter.dynamics.(name) + 1;
pss.tab_parameter.dynamics.(name) = val;
assert(pss.tab_parameter.dynamics.(name) == val)
assert(DebugScript.helper.is_stale(net))
sv = DebugScript.helper.stale(net);
assert(numel(sv) == 1 && contains(sv, "edit " + name + ": ") && isequal(pss.sct_stale.equilibrium, sv))


%% Local controller assignment of the same values is not an edit
net = DebugScript.helper.build_ieee14();
comp = net.a_Bus{1}.a_Component{1};
comp.add_local_controller("avr-ST1");
avr = comp.a_LocalController{1};
DebugScript.helper.quiet(@() net.initialize);

avr.tab_parameter = avr.tab_parameter;
assert(~DebugScript.helper.is_stale(net))
assert(isempty(DebugScript.helper.stale(net)))


%% Local controller rejects a value of the wrong class
% Component と同じく Parameter の型検査を通り、エラーになって値は変わらない
net = DebugScript.helper.build_ieee14();
comp = net.a_Bus{1}.a_Component{1};
comp.add_local_controller("avr-ST1");
avr = comp.a_LocalController{1};
val_avr  = avr.tab_parameter.dynamics.kap;
val_comp = comp.tab_parameter.dynamics.D;

assert(class_error(@() set_avr_kap(avr)), "AVR で型の違う値を拒否しない")
assert(avr.tab_parameter.dynamics.kap == val_avr)
assert(class_error(@() set_comp_D(comp)), "Component で型の違う値を拒否しない")
assert(comp.tab_parameter.dynamics.D == val_comp)


%% Global controller tab_parameter edit is logged and rebuilt
[net, agc] = build_agc();
DebugScript.helper.quiet(@() net.initialize);
h_dx = agc.f_dx;

agc.tab_parameter.dynamics.kP = [200; 300];
assert(isequal(agc.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", agc.a_Parameter)}.tab_parameter.kP, [200; 300]))
assert(isequal(agc.tab_parameter.dynamics.kP, [200; 300]))
assert(isequal(h_dx, agc.f_dx) && DebugScript.helper.is_stale(net))
sv = DebugScript.helper.stale(net);
assert(numel(sv) == 1 && contains(sv, "edit kP: [100;100] -> [200;300]") && isequal(agc.sct_stale.odefcn, sv))

DebugScript.helper.quiet(@() net.initialize);
assert(~isequal(h_dx, agc.f_dx))
para = agc.tab_parameter.dynamics{:, agc.sv_para};
x = 0.1;  u = [0.01; 0.02];
assert(norm(agc.f_dx(0,x,[],[],u) - agc.fcn_dx(0,x,[],[],u,para,60)) < 1e-12, ...
       "AGC の f_dx が変更前の定数を使っている")


%% Global controller accepts an edit of one row
[net, agc] = build_agc();
DebugScript.helper.quiet(@() net.initialize);

agc.tab_parameter.dynamics.kP(2) = 300;
assert(isequal(agc.tab_parameter.dynamics.kP, [100; 300]))
sv = DebugScript.helper.stale(net);
assert(numel(sv) == 1 && contains(sv, "edit kP: "))


%% Global controller assignment of the same values is not an edit
[net, agc] = build_agc();
DebugScript.helper.quiet(@() net.initialize);

agc.tab_parameter = agc.tab_parameter;
assert(~DebugScript.helper.is_stale(net))
assert(isempty(DebugScript.helper.stale(net)))


function tf = class_error(fcn)
% fcn を実行し、型検査のエラーが出たかを返す
    tf = false;
    try
        fcn();
    catch ME
        tf = string(DebugScript.helper.msg_id(ME)) == "GUILDA:Parameter:ClassNameMismatch";
    end
end


function set_avr_kap(avr)
    avr.tab_parameter.dynamics.kap = "a";
end


function set_comp_D(comp)
    comp.tab_parameter.dynamics.D = "a";
end


function [net, agc] = build_agc()
% IEEE14 母線系の発電機 2 台を制御する AGC を追加する (初期化はしない)
    net = DebugScript.helper.build_ieee14();
    g1  = net.a_Bus{1}.a_Component{1};
    g2  = net.a_Bus{2}.a_Component{1};
    agc = net.add_global_controller("agc-PI", {g1, g2}, parameter=struct(alpha=[1;1], beta=[1;1], kP=100, kI=500));
end
