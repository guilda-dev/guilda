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
comp.add_local_controller(controller.avr.AVR_ST1("avr1"));
avr = comp.a_LocalController{1};
DebugScript.helper.quiet(@() net.initialize);

val = 2 * avr.para_dynamics.kap;
avr.tab_parameter.dynamics.kap = val;
assert(avr.para_dynamics.kap == val && avr.tab_parameter.dynamics.kap == val)
assert(avr.l_staleOdefcn && ~comp.l_staleOdefcn && net.l_staleEquilibrium)
assert(height(net.tab_editLog) == 1 && net.tab_editLog.log == "edit kap")   % 他の列は変更扱いにならない

DebugScript.helper.quiet(@() net.initialize);
assert(~avr.l_staleOdefcn)
x = avr.rv_Xequilibrium + 0.01;  u = avr.rv_Uequilibrium;
V = [real(comp.c_Vequilibrium); imag(comp.c_Vequilibrium)];
para = avr.tab_parameter.dynamics{:, avr.sv_para}.';
assert(norm(avr.f_dx(0,x,V,[0;0],u) - avr.fcn_dx(0,x,V,[0;0],u,para,60)) < 1e-12, ...
       "AVR の f_dx が変更前の定数を使っている")


%% Nested local controller tab_parameter edit is logged
net = DebugScript.helper.build_ieee14();
comp = net.a_Bus{1}.a_Component{1};
comp.add_local_controller(controller.avr.AVR_ST1("avr1"), controller.pss.PSS1("pss1"));
pss = comp.a_LocalController{1}.a_LocalController{1};
DebugScript.helper.quiet(@() net.initialize);

name = pss.sv_para(1);
val  = 2 * pss.para_dynamics.(name) + 1;
pss.tab_parameter.dynamics.(name) = val;
assert(pss.para_dynamics.(name) == val)
assert(pss.l_staleOdefcn && net.l_staleEquilibrium)
assert(height(net.tab_editLog) == 1 && net.tab_editLog.log == "edit " + name)


%% Local controller assignment of the same values is not an edit
net = DebugScript.helper.build_ieee14();
comp = net.a_Bus{1}.a_Component{1};
comp.add_local_controller(controller.avr.AVR_ST1("avr1"));
avr = comp.a_LocalController{1};
DebugScript.helper.quiet(@() net.initialize);

avr.tab_parameter = avr.tab_parameter;
assert(~avr.l_staleOdefcn && ~net.l_staleEquilibrium)
assert(height(net.tab_editLog) == 0)


%% Local controller rejects a value of the wrong class
% Component と同じく Parameter の型検査を通り、値は元に戻る。
% 型検査のエラーはリスナーの中で出るので、MATLAB により警告へ変換される
net = DebugScript.helper.build_ieee14();
comp = net.a_Bus{1}.a_Component{1};
comp.add_local_controller(controller.avr.AVR_ST1("avr1"));
avr = comp.a_LocalController{1};
val_avr  = avr.para_dynamics.kap;
val_comp = comp.para_dynamics.D;

assert(class_warning(@() set_avr_kap(avr)), "AVR で型の違う値を拒否しない")
assert(avr.para_dynamics.kap == val_avr)
assert(class_warning(@() set_comp_D(comp)), "Component で型の違う値を拒否しない")
assert(comp.para_dynamics.D == val_comp)


%% Global controller tab_parameter edit is logged and rebuilt
[net, agc] = build_agc();
DebugScript.helper.quiet(@() net.initialize);

agc.tab_parameter.dynamics.kP = [200; 300];
assert(isequal(agc.para_dynamics.kP, [200; 300]))
assert(isequal(agc.tab_parameter.dynamics.kP, [200; 300]))
assert(agc.l_staleOdefcn && net.l_staleEquilibrium)
assert(height(net.tab_editLog) == 1 && net.tab_editLog.log == "edit kP")

DebugScript.helper.quiet(@() net.initialize);
assert(~agc.l_staleOdefcn)
para = agc.tab_parameter.dynamics{:, agc.sv_para};
x = 0.1;  u = [0.01; 0.02];
assert(norm(agc.f_dx(0,x,[],[],u) - agc.fcn_dx(0,x,[],[],u,para,60)) < 1e-12, ...
       "AGC の f_dx が変更前の定数を使っている")


%% Global controller accepts an edit of one row
[net, agc] = build_agc();
DebugScript.helper.quiet(@() net.initialize);

agc.tab_parameter.dynamics.kP(2) = 300;
assert(isequal(agc.para_dynamics.kP, [100; 300]))
assert(height(net.tab_editLog) == 1 && net.tab_editLog.log == "edit kP")


%% Global controller assignment of the same values is not an edit
[net, agc] = build_agc();
DebugScript.helper.quiet(@() net.initialize);

agc.tab_parameter = agc.tab_parameter;
assert(~agc.l_staleOdefcn && ~net.l_staleEquilibrium)
assert(height(net.tab_editLog) == 0)


function tf = class_warning(fcn)
% fcn を実行し、リスナーのエラーが変換された警告が出たかを返す
    lastwarn("");
    evalc("fcn();");
    [~, id] = lastwarn();
    tf = string(id) == "MATLAB:callback:DynamicPropertyEventError";
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
    agc = controller.agc.broadcast_PI_AGC(net, "agc", g1, g2, alpha=[1;1], beta=[1;1], kP=100, kI=500);
    net.add_global_controller(agc);
end
