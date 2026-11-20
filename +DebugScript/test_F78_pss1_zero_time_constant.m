% F78 PSS1 の進み遅れブロックの時定数 0
%
%   教科書 (5.35b) の実現 td*dxi = -xi + (1 - td/tn)*v, 出力 (tn/td)*(v - xi) は、
%   tn = td = 0 で 0/0、tn = 0 で -Inf になる。次の規則で扱う (notes/st1-limiter-pss1.md)。
%   - tn = td = 0 のブロックは恒等 (状態は 0 のまま)。表 5.7 の例 1 (tn2 = td2 = 0)
%   - tn = 0, td > 0 のブロックは 1 次遅れ 1/(1 + td*s)。状態がブロックの出力になる
%   - td = 0, tn ~= 0 のブロックは非プロパーなので initialize でエラー (GUILDA:PSS1:ImproperLeadLag)
%   伝達関数は Jacobian から作った Cyx (sM - Axx)^-1 Bxu + Dyu と式を比べる。
%
% 実行: runtests("DebugScript.test_F78_pss1_zero_time_constant")  または  DebugScript.run_all("Features","F78")

%% Example 1 of Table 5.7 initializes, simulates and linearizes without NaN
net = network.IEEE9bus(LocalController=false);
p = struct(kpss=9.5, tWS=1.4, td1=0.033, tn1=0.154, td2=0, tn2=0);
for b = 1:3
    gen = net.a_Bus{b}.a_Component{1};
    gen.add_local_controller("avr-ST1");
    gen.add_local_controller("pss-PSS1", parameter=p);
end
lastwarn("");
DebugScript.helper.quiet(@() net.initialize);
[~, s_id] = lastwarn;
assert(s_id == "", "initialize warned: %s", s_id)
pss = net.a_Bus{1}.a_Component{1}.pss;
assert(isequal(pss.rv_Xequilibrium, zeros(3,1)))
flag = pss.validate(false);
assert(~any(flag.contract.status == "FAIL"))
sc = net.add_scenario("fault");
sc.add_fault("B007", [1, 1.05]);
sol = DebugScript.helper.quiet(@() net.simulate("fault", Time=[0, 3]));
assert(sol.rv_t(end) == 3 && all(isfinite(sol.rm_variable(:))))
% 恒等のブロックの状態 xi2 は 0 のまま
lv = sol.tab_variable.Owner == pss.s_tag & sol.tab_variable.Name == "xi2";
assert(max(abs(sol.rm_variable(:, lv))) == 0)
sys = net.get_sys();
assert(all(isfinite(sys.A(:))))


%% The transfer function from the Jacobians matches the formula for zero time constants
% [kpss, tWS, tn1, td1, tn2, td2]: 通常, 恒等 (2 つ目), 恒等 (1 つ目), 1 次遅れ (2 つ目), 1 次遅れ (1 つ目)
rm_case = [ 9.5, 1.4, 0.154, 0.033, 0.00, 0.00
           20.0,  10,  0.05,  0.02, 3.00, 5.40
           20.0,  10,  0.00,  0.00, 3.00, 5.40
           20.0,  10,  0.05,  0.02, 0.00, 0.10
           20.0,  10,  0.00,  0.10, 3.00, 5.40
           20.0,  10,  0.00,  0.00, 0.00, 0.00];
rv_w = [0.1, 1, 6, 30];
for k = 1:size(rm_case, 1)
    c = rm_case(k, :);
    param = [c, -Inf, Inf];
    x = zeros(3,1);  V = [1; 0];  u = 0;
    M = controller.pss.PSS1.fcn_Mass(0, x, V, u, param, 60);
    [Axx, ~, Bxu] = controller.pss.PSS1.Jacobi_dx(0, x, V, u, param, 60);
    [Cyx, ~, Dyu] = controller.pss.PSS1.Jacobi_Y(0, x, V, u, param, 60);
    for w = rv_w
        s = 1j*w;
        G = Cyx*((s*M - Axx)\Bxu) + Dyu;
        G_ref = c(1) * c(2)*s/(1 + c(2)*s) * lead_lag(s, c(3), c(4)) * lead_lag(s, c(5), c(6));
        assert(abs(G - G_ref) <= 1e-10*max(1, abs(G_ref)), "case %d, w = %g: G = %s, formula %s", k, w, num2str(G), num2str(G_ref))
    end
end


%% The Jacobians match the numerical derivatives away from the equilibrium
rm_case = [ 9.5, 1.4, 0.154, 0.033, 0.00, 0.00
           20.0,  10,  0.05,  0.02, 0.00, 0.10
           20.0,  10,  0.00,  0.10, 3.00, 5.40
           20.0,  10,  0.05,  0.02, 3.00, 5.40];
x = [0.01; -0.02; 0.005];  V = [1; 0.1];  u = 0.003;
for k = 1:size(rm_case, 1)
    param = [rm_case(k, :), -Inf, Inf];
    [Axx, ~, Bxu] = controller.pss.PSS1.Jacobi_dx(0, x, V, u, param, 60);
    [Cyx, ~, Dyu] = controller.pss.PSS1.Jacobi_Y(0, x, V, u, param, 60);
    Axx_num = tools.fd_jacobian(@(z) controller.pss.PSS1.fcn_dx(0, z, V, u, param, 60), x, Step=1e-6);
    Bxu_num = tools.fd_jacobian(@(z) controller.pss.PSS1.fcn_dx(0, x, V, z, param, 60), u, Step=1e-6);
    Cyx_num = tools.fd_jacobian(@(z) controller.pss.PSS1.fcn_y(0, z, V, u, param, 60), x, Step=1e-6);
    Dyu_num = tools.fd_jacobian(@(z) controller.pss.PSS1.fcn_y(0, x, V, z, param, 60), u, Step=1e-6);
    assert(max(abs([Axx(:) - Axx_num(:); Bxu(:) - Bxu_num(:); Cyx(:) - Cyx_num(:); Dyu(:) - Dyu_num(:)])) < 1e-6, "case %d", k)
end


%% A block with td = 0 and tn ~= 0 stops initialize
[net, gen] = DebugScript.helper.build_3bus("gen-1axis");
gen.add_local_controller("avr-ST1");
gen.add_local_controller("pss-PSS1", parameter=struct(tn2=0.1, td2=0));
ME = [];
try
    DebugScript.helper.quiet(@() net.initialize);
catch ME
end
assert(~isempty(ME) && DebugScript.helper.msg_id(ME) == "GUILDA:PSS1:ImproperLeadLag")
assert(contains(ME.message, "td2 = 0"))
% 直すと動く
gen.pss.tab_parameter.dynamics.td2 = 0.1;
DebugScript.helper.quiet(@() net.initialize);


function G = lead_lag(s, tn, td)
% 進み遅れブロック (1 + tn*s)/(1 + td*s)。tn = td = 0 は 1
    G = (1 + tn*s)/(1 + td*s);
end
