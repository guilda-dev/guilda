% F65 既定の Static の AVR と調速機、Component.rv_Uoffset
%
%   同期発電機 (component.generator.*) は作られたときから avr-static と gov-static を持つ。
%   どちらも状態がなく、入力をそのまま出す (Pmech = Pmech_ref, Vfield = Vfd_ref + Vpss。直達項 1)。
%   Vfd_ref と Pmech_ref は平衡値のままなので、PSS がなければ発電機は制御器がないときと同じに動く。
%   Static の AVR の下にも PSS を付けられる。ほかの AVR・調速機は警告なしに置き換える。
%   組み込み系統の LocalController=false (既定) は local_controller/ の制御器を付けず、発電機には Static だけが残る。
%   rv_Uoffset は simulate の入力のオフセット e と同じ規則 (ローカル制御器が出す入力は 0)。
%
% 実行: runtests("DebugScript.test_F65_static_controllers")  または  DebugScript.run_all("Features","F65")

%% A generator has the Static AVR and governor from its creation
bus = PowerNetwork().add_bus();
gen = bus.add_component("gen-park");
assert(isequal(cellfun(@(c) c.key, gen.a_LocalController), ["avr-static"; "gov-static"]))
assert(isa(gen.avr, "controller.avr.Static") && isa(gen.governor, "controller.governor.Static") && isempty(gen.pss))
assert(gen.avr.s_tag == gen.s_tag + "CA1" && gen.governor.s_tag == gen.s_tag + "CG1")
assert(isequal(gen.avr.sv_u, ["Vfd_ref"; "Vpss"]) && gen.avr.sv_y == "Vfield" && isempty(gen.avr.sv_x))
assert(gen.governor.sv_u == "Pmech_ref" && gen.governor.sv_y == "Pmech" && isempty(gen.governor.sv_x))
% 負荷には付かない
ld = bus.add_component("load-impedance");
assert(isempty(ld.a_LocalController))


%% Another AVR or governor replaces the Static without a warning
[~, gen] = DebugScript.helper.build_3bus("gen-park");
lastwarn("");
w = warning("error", "GUILDA:Component:ReplaceController"); %#ok<CTPCT>
c_w = onCleanup(@() warning(w));
avr = gen.add_local_controller("avr-ST1");
gov = gen.add_local_controller("gov-LPT1");
assert(lastwarn == "")
assert(gen.avr == avr && gen.governor == gov && numel(gen.a_LocalController) == 2)
% Static は番号に数えないので、タグは Static がないときと同じ
assert(avr.s_tag == gen.s_tag + "CA1" && gov.s_tag == gen.s_tag + "CG2")
clear c_w
% Static でない AVR の置き換えは今まで通り警告する
ME = [];
try
    w = warning("error", "GUILDA:Component:ReplaceController"); %#ok<CTPCT>
    c_w = onCleanup(@() warning(w));
    gen.add_local_controller("avr-DC1");
catch ME
end
clear c_w
assert(~isempty(ME) && DebugScript.helper.msg_id(ME) == "GUILDA:Component:ReplaceController")


%% A local controller on Pmech and Vfield takes the place of both Statics
[~, gen] = DebugScript.helper.build_3bus("gen-park");
lqr = gen.add_local_controller("local-LQR");
assert(isscalar(gen.a_LocalController) && gen.a_LocalController{1} == lqr && isempty(gen.governor))
% Static でない調速機とは今まで通り重なりのエラー
[~, gen] = DebugScript.helper.build_3bus("gen-park");
gov = gen.add_local_controller("gov-LPT1");
ME = [];
try
    gen.add_local_controller("local-LQR");
catch ME
end
assert(DebugScript.helper.msg_id(ME) == "GUILDA:Component:ControllerOutputOverlap" && gen.governor == gov)


%% A PSS goes under the Static AVR: its Vpss adds to the field voltage
[net, gen] = DebugScript.helper.build_3bus("gen-park");
pss = gen.add_local_controller("pss-PSS1");
assert(isa(gen.avr, "controller.avr.Static") && gen.pss == pss && pss.a_Component == gen.avr)
DebugScript.helper.quiet(@() net.initialize);
assert(isequal(gen.avr.rv_Uequilibrium, [gen.rv_Uequilibrium(gen.sv_u == "Vfield"); 0]))
% Vpss の出力は名前で Static の AVR の入力 Vpss へつながる
[tab, ~, ~, tc] = net.get_variable_map();
i_in = find(tab.Kind == "uc" & tab.Owner == gen.avr.s_tag & tab.Name == "Vpss");
i_src = tc.SourceIndex(tc.TargetIndex == i_in & tc.Kind == "local");
assert(isscalar(i_src) && tab.Owner(i_src) == pss.s_tag && tab.Name(i_src) == "Vpss")
% 外乱なしでは平衡点に留まり、事故では PSS が動く
sol = DebugScript.helper.quiet(@() net.simulate(DebugScript.helper.no_disturbance(net), Time=[0, 2]));
assert(sol.flag == 1 && DebugScript.helper.max_state_drift(sol) < 1e-9)
sc = net.add_scenario("fault");
sc.add_fault("B003", [0.5, 0.55]);
sol = DebugScript.helper.quiet(@() net.simulate("fault", Time=[0, 2]));
tab_v = sol.tab_variable;
assert(sol.flag == 1 && max(abs(sol.rm_variable(:, tab_v.Owner == pss.s_tag & tab_v.Kind == "x")), [], "all") > 1e-6)
% Static の AVR を別の AVR で置き換えると、PSS は新しい AVR へ移る (警告なし)
avr = gen.add_local_controller("avr-ST1");
assert(gen.pss == pss && pss.a_Component == avr && isvalid(pss))


%% Networks built with LocalController=false keep only the Static AVR and governor
for s_net = ["IEEE9bus", "IEEE68bus", "IEEJ_EAST10", "IEEJ_WEST10"]
    mk = str2func("network." + s_net);
    for c_arg = {{}, {"LocalController", false}}    % 既定は false
        net = DebugScript.helper.quiet(@() mk(c_arg{1}{:}));
        for b = 1:numel(net.a_Bus)
            for c = 1:numel(net.a_Bus{b}.a_Component)
                comp = net.a_Bus{b}.a_Component{c};
                sv_key = string(cellfun(@(con) char(con.key), comp.a_LocalController, "UniformOutput", false));
                if isa(comp, "component.generator.abstract")
                    assert(isequal(sv_key(:)', ["avr-static", "gov-static"]) && isempty(comp.avr.a_LocalController), s_net + ": " + comp.s_tag)
                else
                    assert(isempty(sv_key), s_net + ": " + comp.s_tag)
                end
            end
        end
    end
end
% LocalController=true の系統 (AVR と PSS) の発電機は Static の調速機を持つ
net = network.IEEE9bus(LocalController=true);
gen = net.a_Bus{1}.a_Component{1};
assert(isa(gen.avr, "controller.avr.AVR_ST1") && isa(gen.governor, "controller.governor.Static"))


%% rv_Uoffset is 0 on the inputs a local controller drives and rv_Uequilibrium elsewhere
net = network.IEEE9bus(LocalController=true);
gen = net.a_Bus{1}.a_Component{1};
assert(isequal(gen.rv_Uoffset, [0; 0]))
net0 = network.IEEE9bus(LocalController=false);
remove_controllers(net0);
gen0 = net0.a_Bus{1}.a_Component{1};
assert(isequal(gen0.rv_Uoffset, gen0.rv_Uequilibrium) && all(gen0.rv_Uoffset ~= 0))
% 一方だけを外すと、その入力だけが平衡値になる
gen.remove_local_controller(gen.governor.s_tag);
DebugScript.helper.quiet(@() net.initialize);
assert(gen.rv_Uoffset(gen.sv_u == "Pmech") == gen.rv_Uequilibrium(gen.sv_u == "Pmech"))
assert(gen.rv_Uoffset(gen.sv_u == "Vfield") == 0)
% simulate の e と同じ: e は接続 "equilibrium" の入力だけに平衡値を置く
[tab, ~, ~, tc] = net.get_variable_map();
iv_u = find(tab.Kind == "u" & tab.Owner == gen.s_tag);
lv_eq = arrayfun(@(i) any(tc.TargetIndex == i & tc.Kind == "equilibrium"), iv_u);
assert(isequal(gen.rv_Uoffset ~= 0, lv_eq))
% グローバル制御器だけが出す入力は、平衡値に足される (オフセットは平衡値のまま)
[net3, g3] = DebugScript.helper.build_3bus("gen-park");
g3.remove_local_controller(g3.governor.s_tag);
net3.add_global_controller("agc-PI", g3.s_tag);
DebugScript.helper.quiet(@() net3.initialize);
assert(g3.rv_Uoffset(g3.sv_u == "Pmech") == g3.rv_Uequilibrium(g3.sv_u == "Pmech"))


%% simulate with only Static controllers gives the trajectories of the network without them
[r_s, net_s] = fault_run(true);
[r_0, net_0] = fault_run(false);
for b = 1:numel(net_0.a_Bus)
    assert(max(abs(r_s.Bus(b).V{:,:} - r_0.Bus(b).V{:,:}), [], "all") < 1e-6, "V of bus " + b)
    for c = 1:numel(net_0.a_Bus{b}.a_Component)
        X0 = r_0.Bus(b).Component(c).X{:,:};
        if isempty(X0)
            continue    % a load without states
        end
        assert(max(abs(r_s.Bus(b).Component(c).X{:,:} - X0), [], "all") < 1e-6, "x of " + net_0.a_Bus{b}.a_Component{c}.s_tag)
    end
end
% Static を外す (trip) と、その入力は平衡値になり、外さないときと同じ
sc = net_s.add_scenario("trip_static");
sc.add_fault("B008", [1, 1.05]);
sc.add_trip(net_s.a_Bus{2}.a_Component{1}.governor.s_tag, 0.5);
r_t = net_s.simulate("trip_static", Time=[0, 3]).odeResults;
% 刻みは違うので、時刻をそろえて比べる (相の境界で重なる時刻は後の値)
t_cmp = linspace(0, 3, 61)';
assert(max(abs(sample(r_t, t_cmp) - sample(r_s, t_cmp)), [], "all") < 1e-4)


%% The ODE eigenvalues of generators with Static controllers are those without them
net_s = network.IEEE9bus(LocalController=false);    % Static だけ
net_0 = network.IEEE9bus(LocalController=false);
remove_controllers(net_0);
e_s = DebugScript.helper.finite_eigs(net_s.get_sys("Type", "ODE"));
e_0 = DebugScript.helper.finite_eigs(net_0.get_sys("Type", "ODE"));
assert(DebugScript.helper.same_eigs(e_s, e_0, 1e-8))
% Static の出力の Jacobian は直達項 1 (空にすると get_linear_matrix で 0 になる)
gov = net_s.a_Bus{1}.a_Component{1}.governor;
[Cyx, Dyv, Dyu] = gov.f_JacobiY(0, zeros(0,1), [1; 0], 0.5);
assert(isequal(size(Cyx), [1, 0]) && isequal(Dyv, zeros(1,2)) && Dyu == 1)
avr = net_s.a_Bus{1}.a_Component{1}.avr;    % Vfield = Vfd_ref + Vpss
[~, Dyv, Dyu] = avr.f_JacobiY(0, zeros(0,1), [1; 0], [1.5; 0.1]);
assert(isequal(Dyv, zeros(1,2)) && isequal(Dyu, [1, 1]) && avr.f_Y(0, zeros(0,1), [1; 0], [1.5; 0.1]) == 1.6)
assert(isequal(size(gov.f_Mass([],[],[],[])), [0, 0]))
[Axx, Bxv, Bxu] = gov.f_JacobiDx(0, zeros(0,1), [1; 0], 0.5);
assert(isequal(size(Axx), [0, 0]) && isequal(size(Bxv), [0, 2]) && isequal(size(Bxu), [0, 1]))


%% add_input on Pmech acts as on a generator without a governor
r = cell(1, 2);
for k = 1:2
    net = network.IEEE9bus(LocalController=false);    % Static だけ
    if k == 2
        remove_controllers(net);
    end
    sc = net.add_scenario("in");
    sc.add_input("B002SG1", "Pmech", 0.05, [0.5, 1.5]);
    r{k} = net.simulate("in", Time=[0, 3]).odeResults;
end
d = r{1}.Bus(2).Component(1).X.delta - r{2}.Bus(2).Component(1).X.delta;
assert(max(abs(d)) < 1e-6)
assert(max(abs(r{1}.Bus(2).Component(1).X.omega)) > 1e-4)   % 入力は効いている


function [r, net] = fault_run(l_static)
    % IEEE9bus の発電機に Static だけを付けた (l_static) 系統と、何も付けない系統の事故応答
    net = network.IEEE9bus(LocalController=false);    % Static だけ
    if ~l_static
        remove_controllers(net);
    end
    sc = net.add_scenario("fault");
    sc.add_fault("B008", [1, 1.05]);
    r = net.simulate("fault", Time=[0, 3]).odeResults;
end

function X = sample(r, t)
    % The states of B002SG1 at the times t (at a time of two phases, the later value)
    [t_u, iv] = unique(r.t, "last");
    X = interp1(t_u, r.Bus(2).Component(1).X{iv,:}, t);
end

function remove_controllers(net)
    % 各機器の制御器 (Static も) をすべて外して平衡点を求め直す
    for b = 1:numel(net.a_Bus)
        for c = 1:numel(net.a_Bus{b}.a_Component)
            comp = net.a_Bus{b}.a_Component{c};
            for con = reshape(comp.a_LocalController, 1, [])
                comp.remove_local_controller(con{1}.s_tag, RemoveNested=true);
            end
        end
    end
    DebugScript.helper.quiet(@() net.initialize);
end
