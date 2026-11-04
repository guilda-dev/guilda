% I58 局所制御器が駆動する入力への外部信号
%
% 局所制御器が駆動する入力 (AVR 配下の Vfield など) に入力イベントや大域制御器の出力を与えると、
% simulate は制御器の出力に加算する。get_sys の説明とヤコビアンは加算を前提とするので、
% 小さなステップの応答が線形モデルと一致することを数値で確認する。
%
% 実行: runtests("DebugScript.test_I58_input_under_local_controller")  または  DebugScript.run_all("Features","I58")

% 共通設定 (各テストの前に毎回実行される)
r_step = 1e-3;
str_unit = "SG1B003";


%% A step on an input driven by an AVR matches get_sys
net = build_with_avr(str_unit);
gen = component_of(net, str_unit);
assert(any(string(gen.a_LocalController{1}.sv_y) == "Vfield"))
[r_err, r_max] = error_to_linear(net, str_unit, "Vfield", r_step);
assert(r_max > 1e-8, "the step has no effect: %g", r_max)
assert(r_err < 0.01, "relative error %g", r_err)


%% The recorded input is the output of the controller plus the event
net = build_with_avr(str_unit);
gen = component_of(net, str_unit);
r_vf = gen.rv_Uequilibrium(gen.sv_u == "Vfield");
r = simulate_step(net, str_unit, "Vfield", r_step, [0,1e-3]);
U = component_result(r, net, str_unit).U;
assert(abs(U.Vfield(end) - (r_vf + r_step)) < 1e-6, "Vfield %g", U.Vfield(end) - r_vf)


%% A step on an input no controller drives still matches get_sys
net = build_with_avr(str_unit);
[r_err, r_max] = error_to_linear(net, str_unit, "Pmech", r_step);
assert(r_max > 1e-5, "the step has no effect: %g", r_max)
assert(r_err < 0.01, "relative error %g", r_err)


%% A global controller on a driven input adds to the local controller
% AGC も LQR も SG1B003 の Pmech を駆動する。加算のときだけ AGC を含む線形モデルと一致する
net = DebugScript.helper.build_ieee14();
gen = component_of(net, str_unit);
evalc("gen.add_local_controller(controller.local_LQR(""lqr"", Input=""Pmech""))");
net.add_global_controller(controller.agc.broadcast_PI_AGC(net, "agc", str_unit, "SG1B001"));
DebugScript.helper.quiet(@() net.initialize);
[r_err, r_max] = error_to_linear(net, "SG1B002", "Pmech", r_step);
assert(r_max > 1e-6, "the step has no effect: %g", r_max)
assert(r_err < 0.01, "relative error %g", r_err)


%% Without an external signal the equilibrium is kept
net = build_with_avr(str_unit);
r = net.simulate([0,5]).odeResults;
gen = component_of(net, str_unit);
X = component_result(r, net, str_unit).X;
assert(max(abs(X.omega - gen.rv_Xequilibrium(gen.sv_x == "omega"))) < 1e-9)


function net = build_with_avr(str_unit)
    net = DebugScript.helper.build_ieee14();
    component_of(net, str_unit).add_local_controller(controller.avr.AVR_ST1("avr"), controller.pss.PSS1("pss"));
    DebugScript.helper.quiet(@() net.initialize);
end

function comp = component_of(net, str_unit)
    c_comp = cellfun(@(b) b.a_Component, net.a_Bus, "UniformOutput", false);
    c_comp = vertcat(c_comp{:});
    comp = c_comp{cellfun(@(c) string(c.str_tag) == str_unit, c_comp)};
end

function res = component_result(r, net, str_unit)
    i_bus = find(cellfun(@(b) any(cellfun(@(c) c == component_of(net, str_unit), b.a_Component)), net.a_Bus));
    res = r.Bus(i_bus).Component(1);
end

function r = simulate_step(net, str_unit, str_input, r_step, rv_time)
    ev = DebugScript.helper.scenario("step", net, "TimeSpan", rv_time, "InputUnit", str_unit, "InputName", str_input, "InputValue", r_step);
    r = net.simulate(rv_time, ev).odeResults;
end

function [r_err, r_max] = error_to_linear(net, str_unit, str_input, r_step)
% Relative 2-norm error of the omega of the unit to the Kron model, and the largest change of omega.
    rv_time = [0,10];
    % 既定の許容誤差では応答 (1e-5 程度) に対して積分誤差が目立つ
    net.solver_ODE.RelativeTolerance = 1e-8;
    net.solver_ODE.AbsoluteTolerance = 1e-10;
    r = simulate_step(net, str_unit, str_input, r_step, rv_time);

    gen = component_of(net, str_unit);
    sys = net.get_sys("Algorithm", "Kron");
    i_u = string(sys.InputName) == gen.attach_tag(str_input);
    i_x = string(sys.StateName) == gen.attach_tag("omega");
    assert(nnz(i_u) == 1 && nnz(i_x) == 1)

    % Trapezoidal rule: E may be singular
    r_dt = 1e-3;
    rv_t = (rv_time(1):r_dt:rv_time(2)).';
    L = sparse(sys.E)/r_dt - sparse(sys.A)/2;
    R = sparse(sys.E)/r_dt + sparse(sys.A)/2;
    b = sys.B(:,i_u)*r_step;
    x = zeros(size(sys.A,1),1);
    rv_lin = zeros(size(rv_t));
    dL = decomposition(L);
    for k = 2:numel(rv_t)
        x = dL\(R*x + b);
        rv_lin(k) = x(i_x);
    end

    res = component_result(r, net, str_unit).X;
    [rv_tu, iv_u] = unique(r.t);
    rv_non = interp1(rv_tu, res.omega(iv_u), rv_t) - gen.rv_Xequilibrium(gen.sv_x == "omega");
    r_err = norm(rv_non - rv_lin)/norm(rv_lin);
    r_max = max(abs(rv_non));
end
