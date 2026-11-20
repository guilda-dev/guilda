% F83 エネルギー関数のヘッセ行列 (get_hessian、ポート "PI")
%
%   H = comp.get_hessian();              % 平衡点
%   H = comp.get_hessian(x, V, u);       % 任意の点 (V = [Vre; Vim])
%   % dx/dt = -H.R (H.Hxx x + H.Hxv v),  w_dev = H.Hvx x + H.Hvv v,  v = [theta; V]
%
% 同期発電機 (classical, one_axis, two_axis, park)、負荷 (impedance, power, current, ZIP)、インバータ
% (GFMInverter.VSG_classical, GFLInverter.Static) が実装する。インバータは Tutorial10bus にないので build_3bus の網で確かめる
% (VSG は alpha = 0 と alpha = 0.3 の 2 台)。
% get_linear_matrix のヤコビアンを PI ポートへ変換したものと、平衡点と平衡点でない点で一致すること
% (-R [Hxx Hxv] が状態の行、[Hvx Hvv] が w_dev = -[P; Q/V] の行)、損失のない機器で対称なこと、
% R が正則なこと、対応しないクラスと縮退したパラメータではクラス名を示すエラーになることを確かめる。
%
% 実行: runtests("DebugScript.test_F83_energy_hessian")  または  DebugScript.run_all("Features","F83")

% 共通設定 (最初に 1 回だけ実行され、変数は全テストで共有される)
net = DebugScript.helper.quiet(@() network.Tutorial10bus());   % 発電機と負荷のクラスを含む網
DebugScript.helper.quiet(@() net.initialize);
sv_class = ["component.generator.classical", "component.generator.one_axis", "component.generator.two_axis", ...
            "component.generator.park", "component.load.impedance", "component.load.power", ...
            "component.load.ZIP", "component.load.current", ...
            "component.GFMInverter.VSG_classical", "component.GFLInverter.Static"];
a_comp = {};
for b = 1:numel(net.a_Bus)
    a_comp = [a_comp, net.a_Bus{b}.a_Component(:).']; %#ok<AGROW>
end
a_comp = a_comp(ismember(cellfun(@class, a_comp, "UniformOutput", false), sv_class));
% Tutorial10bus にないクラス (インバータ) は build_3bus の網から取る
dic_key = GUILDA.keymap("Component");
sv_key = keys(dic_key);
for s_class = setdiff(sv_class, string(cellfun(@class, a_comp, "UniformOutput", false)), "stable")
    [net3, comp3] = DebugScript.helper.build_3bus(sv_key(values(dic_key) == s_class));
    DebugScript.helper.quiet(@() net3.initialize);
    a_comp = [a_comp, {comp3}]; %#ok<AGROW>
end
% 電流を alpha だけ回す VSG (動揺方程式は回す前の電流の仮想電力) も加える
[net3, vsg_rot] = DebugScript.helper.build_3bus("gfm-vsg-classical");
vsg_rot.tab_parameter.dynamics.alpha = 0.3;
DebugScript.helper.quiet(@() net3.initialize);
a_comp = [a_comp, {vsg_rot}];
r_tol = 1e-8;   % 相対誤差


%% Every class that implements the form is in the test networks
assert(all(ismember(sv_class, cellfun(@class, a_comp, "UniformOutput", false))))


%% The blocks match the Jacobian of get_linear_matrix at the equilibrium
for k = 1:numel(a_comp)
    comp = a_comp{k};
    [x, V, u] = equilibrium_point(comp);
    [r_xerr, r_werr] = consistency_error(comp, x, V, u);
    assert(r_xerr < r_tol && r_werr < r_tol, "%s: 状態の行 %.1e、収支の行 %.1e", comp.s_tag, r_xerr, r_werr)
end


%% The blocks match the Jacobian of get_linear_matrix away from the equilibrium
rng(83)
for k = 1:numel(a_comp)
    comp = a_comp{k};
    [x, V, u] = equilibrium_point(comp);
    x = x + 0.1*randn(size(x));
    V = 1.05*[cos(0.2), -sin(0.2); sin(0.2), cos(0.2)]*V;
    u = u.*(1 + 0.1*randn(size(u)));
    [r_xerr, r_werr] = consistency_error(comp, x, V, u);
    assert(r_xerr < r_tol && r_werr < r_tol, "%s: 状態の行 %.1e、収支の行 %.1e", comp.s_tag, r_xerr, r_werr)
end


%% Lossless devices are symmetric and the impedance load is not
rng(84)
for k = 1:numel(a_comp)
    comp = a_comp{k};
    [x, V, u] = equilibrium_point(comp);
    x = x + 0.1*randn(size(x));
    H = comp.get_hessian(x, V, u);
    Hall = [H.Hxx, H.Hxv; H.Hvx, H.Hvv];
    r_asym = norm(Hall - Hall.', "fro")/norm(Hall, "fro");
    if class(comp) == "component.load.impedance"
        % 損失: Hvv(1,2) - Hvv(2,1) = 2 G V (G = R/|Z|^2)
        r_G = u(1)/(u(1)^2 + u(2)^2);
        assert(abs(H.Hvv(1,2) - H.Hvv(2,1) - 2*r_G*norm(V)) < 1e-12 && r_G > 0, comp.s_tag)
        assert(H.Hvv(2,1) == 0 && abs(H.Hvv(2,2) - u(2)/(u(1)^2 + u(2)^2)) < 1e-12, comp.s_tag)
    elseif class(comp) == "component.load.current"
        % 損失: Hvv(1,2) = -Ip (P = |V| Ip)、無効電力 Q/V = Iq は V によらない
        assert(isequal(H.Hvv, [0, -u(1); 0, 0]) && u(1) < 0, comp.s_tag)
    elseif class(comp) == "component.load.ZIP"
        % 損失: Hvv(1,2) = -Pload f_P'(V) (既定値の定電流 P では -Pload)、Hvv(2,1) = 0
        assert(H.Hvv(2,1) == 0 && H.Hvv(1,2) > 0, comp.s_tag)
        assert(abs(H.Hvv(1,2) + u(1)) < 1e-12 && isequal(comp.tab_parameter.dynamics{1,1:3}, [0, 1, 0]), comp.s_tag)
    elseif isa(comp, "component.GFMInverter.VSG_classical") && comp.tab_parameter.dynamics.alpha ~= 0
        % 状態の行は古典モデルの発電機と同じで Hxx は対称、母線の電力は回るので Hvx ≠ Hxv.'
        assert(norm(H.Hxx - H.Hxx.') < 1e-12 && norm(H.Hvx - H.Hxv.') > 1e-3, comp.s_tag)
    else
        assert(r_asym < 1e-12, "%s: 非対称 %.1e", comp.s_tag, r_asym)
    end
end


%% R is invertible and the names follow the variable map
for k = 1:numel(a_comp)
    comp = a_comp{k};
    H = comp.get_hessian();
    n_x = numel(comp.sv_x);
    assert(isequal(size(H.Hxx), [n_x n_x]) && isequal(size(H.Hxv), [n_x 2]) && isequal(size(H.Hvx), [2 n_x]) ...
           && isequal(size(H.Hvv), [2 2]) && isequal(size(H.R), [n_x n_x]), comp.s_tag)
    if n_x > 0
        assert(rank(H.R) == n_x && rcond(H.R) > 1e-12, "%s: R が特異", comp.s_tag)
    end
    tab = comp.get_variable_map();
    assert(isequal(H.StateName, tab.Label(tab.Kind == "x" & tab.Owner == comp.s_tag)), comp.s_tag)
    s_bus = string(comp.a_Bus.s_tag);
    assert(isequal(H.PortName, ["theta";"V"] + "_" + s_bus), comp.s_tag)
    assert(isequal(replace(tab.Label(tab.Kind == "Vre"), "Vre", "theta"), H.PortName(1)), comp.s_tag)
end


%% The classes without the form stop with the class name
% droop、AVR_ST1、AGC は対応しない (moved from F7)
n = DebugScript.helper.quiet(@() network.Tutorial10bus());
obj = {n.get_element("B005SG1"), DebugScript.helper.build_smib().a_Bus{1}.a_Component{1}};
obj{2}.add_local_controller("avr-ST1");
obj = {obj{1}, obj{2}.a_LocalController{1}, n.a_GlobalController{1}};
sr_id = ["GUILDA:Component:HessianNotSupported", "GUILDA:LocalController:HessianNotSupported", "GUILDA:GlobalController:HessianNotSupported"];
for k = 1:numel(obj)
    try
        obj{k}.get_hessian();
        error("DebugScript:NoError", class(obj{k}) + ".get_hessian がエラーにならない")
    catch ME
        assert(DebugScript.helper.msg_id(ME) == sr_id(k), DebugScript.helper.msg_id(ME))
        assert(contains(ME.message, class(obj{k})) && contains(ME.message, "does not override get_hessian"), ME.message)
    end
end


%% The Static controllers give empty blocks
gen = DebugScript.helper.build_smib().a_Bus{1}.a_Component{1};
assert(isa(gen.avr, "controller.avr.Static") && isa(gen.governor, "controller.governor.Static"))
for con = {gen.avr, gen.governor}
    H = con{1}.get_hessian([], [1; 0], 1);
    assert(isempty(H.Hxx) && isequal(size(H.Hxv), [0 2]) && isequal(size(H.Hvx), [2 0]) ...
           && isequal(H.Hvv, zeros(2)) && isempty(H.R) && isempty(H.StateName))
    assert(isequal(H.PortName, ["theta";"V"] + "_" + string(gen.a_Bus.s_tag)))
end


%% An equal pair of reactances has no energy function
for s_key = ["gen-2axis", "gen-park"]
    [~, g] = DebugScript.helper.build_3bus(s_key);
    p = g.tab_parameter.dynamics;
    p.Xq_p = p.Xq;
    [~, g] = DebugScript.helper.build_3bus(s_key, parameter=p);
    n_x = numel(g.sv_x);
    try
        g.get_hessian(zeros(n_x,1), [1; 0], [0.5; 1.5]);
        error("DebugScript:NoError", s_key + ": Xq_p = Xq でエラーにならない")
    catch ME
        assert(DebugScript.helper.msg_id(ME) == "GUILDA:Component:HessianNotSupported" && contains(ME.message, class(g)), ME.message)
    end
end


function [x, V, u] = equilibrium_point(comp)
% 機器の平衡点 (x, [Vre; Vim], u)
    x = comp.rv_Xequilibrium(:);
    V = [real(comp.c_Vequilibrium); imag(comp.c_Vequilibrium)];
    u = comp.rv_Uequilibrium(:);
end

function [r_xerr, r_werr] = consistency_error(comp, x, V, u)
% get_hessian と get_linear_matrix の PI ポートでのヤコビアンの相対誤差 (状態の行、収支の行)
%   状態: E dx = A x + Bv [Vre; Vim]  ->  dx/d[x; theta; V] = E \ [A, Bv T]
%   収支: w_dev = -[P; Q/V], P + jQ = V conj(I)  (積の微分を含む厳密なヤコビアン)
    H = comp.get_hessian(x, V, u);
    S = comp.get_linear_matrix(x, V, u);
    n_x = numel(x);
    r_V = norm(V);
    T = [-V(2), V(1)/r_V; V(1), V(2)/r_V];                    % d[Vre; Vim]/d[theta; V]
    J_x = S.E \ [S.A, S.B(:,1:2)*T];
    dI  = [S.C(1:2,:), S.D(1:2,1:2)*T];                        % d[Ire; Iim]/d[x; theta; V]
    dVc = [zeros(2,n_x), T];                                   % d[Vre; Vim]/d[x; theta; V]
    I  = comp.f_I(0, x, V, u);
    Ir = real(I);  Ii = imag(I);
    dP = V(1)*dI(1,:) + V(2)*dI(2,:) + Ir*dVc(1,:) + Ii*dVc(2,:);
    dQ = V(2)*dI(1,:) - V(1)*dI(2,:) + Ir*dVc(2,:) - Ii*dVc(1,:);
    r_Q = V(2)*Ir - V(1)*Ii;
    dabsV = [zeros(1,n_x), 0, 1];
    J_w = -[dP; dQ/r_V - r_Q/r_V^2*dabsV];
    J_xH = -H.R*[H.Hxx, H.Hxv];
    J_wH = [H.Hvx, H.Hvv];
    r_xerr = 0;
    if n_x > 0
        r_xerr = max(abs(J_xH - J_x), [], "all")/max(abs(J_x), [], "all");
    end
    r_werr = max(abs(J_wH - J_w), [], "all")/max(abs(J_w), [], "all");
end
