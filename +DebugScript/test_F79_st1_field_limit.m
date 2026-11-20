% F79 AVR_ST1 の出力リミッタ (教科書 (5.32)) と発電機の出力 Ifield
%
%   出力 Vfield = max(min(Vap, gamma_max*|V| - k0*Ifield), gamma_min*|V|)。下限が優先する。
%   既定値 gamma_max = Inf, gamma_min = -Inf, k0 = 0 では今までの式と同じ。
%   Vap の non-windup (Vap_max, Vap_min) はそのまま残り、tap = 0 では kap*Vcom を上下限で切る。
%   Limiter = false はすべての上下限を無視する。
%   AVR は入力 Ifield で発電機の出力 Ifield (= Vfield - Td'*dEq/dt) を読む。
%   gen-classical, gen-droop は Ifield を出さないので、平衡点の値 (= Vfield) のまま。
%   (notes/st1-limiter-pss1.md)
%
% 実行: runtests("DebugScript.test_F79_st1_field_limit")  または  DebugScript.run_all("Features","F79")

%% AVR_ST1 reads Ifield of the generator and its new columns default to no output limit
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
avr = gen.add_local_controller("avr-ST1");
DebugScript.helper.quiet(@() net.initialize);
assert(isequal(avr.sv_u, ["Vref"; "Vpss"; "Ifield"]))
assert(isequal(avr.sv_para(end-2:end), ["gamma_max"; "gamma_min"; "k0"]))
T = avr.tab_parameter.dynamics;
assert(T.gamma_max == Inf && T.gamma_min == -Inf && T.k0 == 0)
assert(isequal(gen.sv_y, ["omega"; "Ifield"]))
assert(avr.iv_obsY(3) == find(gen.sv_y == "Ifield"))
% 平衡点では Ifield = Vfield
assert(abs(avr.rv_Uequilibrium(3) - gen.rv_Uequilibrium(gen.sv_u == "Vfield")) < 1e-12)
flag = avr.validate(false);
assert(~any(flag.contract.status == "FAIL"))
flag = gen.validate(false);
assert(~any(flag.contract.status == "FAIL"))


%% The Ifield output of the generators is Vfield minus the right-hand side of Eq, with matching Jacobians
for s_key = ["gen-1axis", "gen-2axis", "gen-park"]
    [net, gen] = DebugScript.helper.build_3bus(s_key);
    DebugScript.helper.quiet(@() net.initialize);
    p = gen.tab_parameter.dynamics{:, cellstr(gen.sv_para)}';
    nx = numel(gen.rv_Xequilibrium);
    x = gen.rv_Xequilibrium + 0.05*(1:nx)'/nx;
    V = [1.02; 0.15];
    u = gen.rv_Uequilibrium;
    y = gen.fcn_Y(0, x, V, p, 60);
    dx = gen.fcn_dx(0, x, V, u, p, 60);
    assert(abs(y(2) - (u(2) - dx(gen.sv_x == "Eq"))) < 1e-12, s_key)
    [Cyx, Dyv] = feval(class(gen) + ".Jacobi_Y", 0, x, V, p, 60);
    Cyx_num = tools.fd_jacobian(@(z) gen.fcn_Y(0, z, V, p, 60), x, Step=1e-6);
    Dyv_num = tools.fd_jacobian(@(z) gen.fcn_Y(0, x, z, p, 60), V, Step=1e-6);
    assert(max(abs([Cyx(:) - Cyx_num(:); Dyv(:) - Dyv_num(:)])) < 1e-7, s_key)
end


%% Example 1 of Table 5.5 keeps Vfield within the output limits through a fault
net = network.IEEE9bus(LocalController=false);
p = struct(ttr=0.015, tap=0, kap=200, gamma_max=7.00, gamma_min=-6.40, k0=0.04);
for b = 1:3
    net.a_Bus{b}.a_Component{1}.add_local_controller("avr-ST1", parameter=p);
end
DebugScript.helper.quiet(@() net.initialize);
sc = net.add_scenario("fault");
sc.add_fault("B007", [1, 1.05]);
sol = DebugScript.helper.quiet(@() net.simulate("fault", Time=[0, 3]));
assert(sol.rv_t(end) == 3 && all(isfinite(sol.rm_variable(:))))
T = sol.tab_variable;
r_gap_max = -Inf;
for b = 1:3
    gen = net.a_Bus{b}.a_Component{1};
    rm_V   = sol.rm_variable(:, (T.Kind == "Vre" | T.Kind == "Vim") & T.Owner == gen.a_Bus.s_tag);
    rm_x   = sol.rm_variable(:, T.Kind == "x" & T.Owner == gen.s_tag);
    Vabs   = abs(rm_V(:,1) + 1j*rm_V(:,2));
    Vfield = sol.rm_variable(:, T.Kind == "u"  & T.Owner == gen.s_tag & T.Name == "Vfield");
    Ifield = sol.rm_variable(:, T.Kind == "uc" & T.Owner == gen.avr.s_tag & T.Name == "Ifield");
    r_max  = 7.00*Vabs - 0.04*Ifield;
    r_min  = -6.40*Vabs;
    assert(all(Vfield <= max(r_max, r_min) + 1e-6) && all(Vfield >= r_min - 1e-6), gen.s_tag)
    r_gap_max = max(r_gap_max, max(Vfield - r_max));
    % Ifield の入力は発電機の出力と一致する (代数方程式の誤差は Tolerance の程度)
    p_gen = gen.tab_parameter.dynamics{:, cellstr(gen.sv_para)}';
    rv_Ifield_gen = arrayfun(@(k) [0, 1]*gen.fcn_Y(0, rm_x(k,:)', rm_V(k,:)', p_gen, 60), (1:numel(sol.rv_t))');
    assert(max(abs(Ifield - rv_Ifield_gen)) < 1e-4, gen.s_tag)
end
% 地絡の間は上限に当たる
assert(r_gap_max > -1e-6)


%% tap = 0 with finite Vap limits clips kap*Vcom and runs through the fault
net = network.IEEE9bus(LocalController=false);
for b = 1:3
    net.a_Bus{b}.a_Component{1}.add_local_controller("avr-ST1", parameter=struct(ttr=0.015, tap=0, kap=200, Vap_max=5, Vap_min=-5));
end
DebugScript.helper.quiet(@() net.initialize);
sc = net.add_scenario("fault");
sc.add_fault("B007", [1, 1.05]);
sol = DebugScript.helper.quiet(@() net.simulate("fault", Time=[0, 3]));
assert(sol.rv_t(end) == 3)
lv = sol.tab_variable.Name == "Vap";
assert(max(sol.rm_variable(:, lv), [], "all") <= 5 + 1e-8 && min(sol.rm_variable(:, lv), [], "all") >= -5 - 1e-8)
assert(max(sol.rm_variable(:, lv), [], "all") > 5 - 1e-8)


%% The Jacobians of AVR_ST1 match the numerical derivatives in each limit region
% sv_para: ttr, Vap_max, Vap_min, kap, tap, kst, tst, Limiter, gamma_max, gamma_min, k0
V = [0.9; 0.2];
c_case = {
    [0.015, Inf, -Inf, 200, 0,    0, 0, 1, 7, -6.4, 0.04], [1.0; 2.0; 0], [1.1; 0; 1.8]   % 出力の制限なし
    [0.015, Inf, -Inf, 200, 0,    0, 0, 1, 7, -6.4, 0.04], [1.0; 9.0; 0], [1.1; 0; 1.8]   % 上限
    [0.015, Inf, -Inf, 200, 0,    0, 0, 1, 7, -6.4, 0.04], [1.0; -9.;0], [1.1; 0; 1.8]   % 下限
    [0.015, Inf, -Inf, 200, 0,    0, 0, 1, 0.5, 1.0, 0.04], [1.0; 2.0; 0], [1.1; 0; 1.8]  % 上限が下限を下回る
    [0.015, 5,   -5,   200, 0,    0, 0, 1, Inf, -Inf, 0],  [1.0; 2.0; 0], [1.1; 0; 0]    % tap = 0, kap*Vcom が上限の外
    [0.015, 5,   -5,   200, 0,    0, 0, 1, Inf, -Inf, 0],  [1.0; 2.0; 0], [1.0; 0; 0]    % tap = 0, 範囲内
    [0,     5,   -5,   200, 0.05, 0, 0, 1, Inf, -Inf, 0],  [1.0; 2.0; 0], [1.0; 0; 0]    % tap > 0, 範囲内
    };
for k = 1:size(c_case, 1)
    [param, x, u] = c_case{k, :};
    [Axx, Bxv, Bxu] = controller.avr.AVR_ST1.Jacobi_dx(0, x, V, u, param, 60);
    [Cyx, Dyv, Dyu] = controller.avr.AVR_ST1.Jacobi_Y(0, x, V, u, param, 60);
    f  = @(x, V, u) controller.avr.AVR_ST1.fcn_dx(0, x, V, u, param, 60);
    g  = @(x, V, u) controller.avr.AVR_ST1.fcn_y(0, x, V, u, param, 60);
    J = [Axx, Bxv, Bxu; Cyx, Dyv, Dyu];
    J_num = [tools.fd_jacobian(@(z) f(z, V, u), x, Step=1e-7), tools.fd_jacobian(@(z) f(x, z, u), V, Step=1e-7), tools.fd_jacobian(@(z) f(x, V, z), u, Step=1e-7)
             tools.fd_jacobian(@(z) g(z, V, u), x, Step=1e-7), tools.fd_jacobian(@(z) g(x, z, u), V, Step=1e-7), tools.fd_jacobian(@(z) g(x, V, z), u, Step=1e-7)];
    assert(max(abs(J(:) - J_num(:))) < 1e-5, "case %d: %s", k, mat2str(J - J_num, 3))
end
% 上限が下限を下回るときは下限
y = controller.avr.AVR_ST1.fcn_y(0, [1; 2; 0], V, [1.1; 0; 1.8], c_case{4, 1}, 60);
assert(abs(y - 1.0*abs([1, 1j]*V)) < 1e-12)
% Limiter = false は出力の制限も無視する
param = c_case{2, 1};  param(8) = 0;
assert(controller.avr.AVR_ST1.fcn_y(0, [1; 9; 0], V, [1.1; 0; 1.8], param, 60) == 9)


%% A generator without Ifield leaves the input at its equilibrium value
[net, gen] = DebugScript.helper.build_3bus("gen-classical");
% 上限に当たらない広い値 (古典モデルは Vfield が内部電圧なので、上限に当たると代数ループになる)
avr = gen.add_local_controller("avr-ST1", parameter=struct(gamma_max=100, gamma_min=-100, k0=0.04));
DebugScript.helper.quiet(@() net.initialize);
assert(avr.iv_obsY(3) == 0 && avr.iv_obsX(3) == 0)
assert(abs(avr.rv_Uequilibrium(3) - gen.rv_Uequilibrium(gen.sv_u == "Vfield")) < 1e-12)
sc = net.add_scenario("fault");
sc.add_fault("B003", [1, 1.05]);
sol = DebugScript.helper.quiet(@() net.simulate("fault", Time=[0, 2]));
lv = sol.tab_variable.Owner == avr.s_tag & sol.tab_variable.Name == "Ifield";
assert(sol.rv_t(end) == 2 && all(sol.rm_variable(:, lv) == avr.rv_Uequilibrium(3)))


%% The output limits are checked at the equilibrium unless Limiter is false
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
avr = gen.add_local_controller("avr-ST1", parameter=struct(gamma_max=0.5));
ME = [];
try
    DebugScript.helper.quiet(@() net.initialize);
catch ME
end
assert(~isempty(ME) && DebugScript.helper.msg_id(ME) == "GUILDA:AVR_ST1:InvalidValueRange")
avr.tab_parameter.dynamics.Limiter = false;
DebugScript.helper.quiet(@() net.initialize);
