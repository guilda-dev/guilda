% Developer script: needs Symbolic Math Toolbox (syms, jacobian, matlabFunction).
% It checks hand-written Jacobians against symbolic ones and is not part of the GUILDA runtime.
%
% 制御器のクラスの静的メソッド fcn_dx・fcn_y・Jacobi_dx・Jacobi_Y を直接呼び、記号計算で作った
% 右辺 [f; y] とそのヤコビアン d[f; y]/d[x; V; u] と比べます。制限のある制御器は、制限の領域
% ごとにランダムな点で比べます。期待値は制限のないモデルの式から作り、各クラスが実装している
% 規則のとおりに行を置き換えます (止まる状態の行は 0、飽和した出力は制限値)。
%   controller.avr.AVR_DC1 : Vap と Vfld の non-windup 制限 (制限に達し、さらに外へ向かう間は止める)
%   controller.avr.AVR_ST1 : Vap の non-windup 制限、tap = 0 の静的な増幅器の飽和、出力の制限
%   controller.pss.PSS1    : 出力 Vpss の飽和、tn = td = 0 と tn = 0 の進み遅れブロック
% 実行: GUILDA を起動したあと controller.validate (パッケージの中のスクリプトなので run では呼べません)
% 領域ごとに PASS / FAIL を表示し、1 つでも FAIL があれば最後に error にします。

if exist("syms", "file") == 0 || ~license("test", "Symbolic_Toolbox")
    error("validate:NoSymbolicToolbox", "This script needs the Symbolic Math Toolbox.")
end

rng(0)              % 再現できる乱数
n_point = 200;      % 領域ごとの点の数
tol     = 1e-9;     % 許容誤差 (|差| / max(1, |期待値|))
omega0  = 60;       % [Hz] 基準周波数 (どの制御器も使わない)

syms Vre Vim real
Vabs  = sqrt(Vre^2 + Vim^2);
f_V   = @() [0.9 + 0.2*rand; 0.4*rand - 0.2];         % 端子電圧 [real; imag] (|V| は 1 前後)
r_in  = @(lo, hi) lo + (hi - lo)*(0.05 + 0.9*rand);   % (lo, hi) の内側の乱数
r_pos = @() 0.1 + rand;                               % 正の乱数 (境界から離す量)

% c_case の各行: {制御器の名前, クラスの静的メソッド, 記号変数 [x; V; u], 領域の cell}
% 領域の cell の各行: {領域の名前, パラメータ (sv_para の順), 点 [x; V; u] を返す関数, 期待する [f; y]}
c_case = cell(0, 4);

%% AVR_DC1
% 状態 x = [Vtr; Vap; Vfld; Vst]、入力 u = [Vref; Vpss]、出力 y = Vfld
syms Vtr Vap Vfld Vst Vref Vpss real
sv_para = ["ttr"; "Vap_max"; "Vap_min"; "kap"; "tap"; "aex1"; "aex2"; "tex"; "bex"; "kst"; "tst"; "Vfld_max"; "Vfld_min"; "Limiter"];
sct_p = struct(ttr=0.01, Vap_max=5, Vap_min=-5, kap=20, tap=0.2, aex1=1, aex2=0.0039, tex=0.314, ...
               bex=1.555, kst=0.063, tst=0.35, Vfld_max=2, Vfld_min=-2, Limiter=true);
f_param = @(sct) arrayfun(@(s) double(sct.(s)), sv_para);
sct_nolim = sct_p;
sct_nolim.Limiter = false;

% 制限のないモデル
Vcom = Vref + Vpss - Vtr - Vst;                                    % コンパレータ
f_ap = -Vap + sct_p.kap*Vcom;                                      % 増幅器
g_ex = @(v) (sct_p.aex1 + sct_p.aex2*exp(sct_p.bex*v))*v;          % 励磁器の飽和項 (dx3 = Vap - g_ex(Vfld))
sym_rhs = [-Vtr + Vabs; f_ap; Vap - g_ex(Vfld); -Vst; Vfld];
f_freeze = @(iv) sym_rhs .* double(~ismember((1:5)', iv));        % 止まる状態の行を 0 にする

% 点 [Vtr; Vap; Vfld; Vst; Vre; Vim; Vref; Vpss]。Vref は dx2 = -Vap + kap*Vcom が d になるように決める
f_vref = @(p, d) [p(1:6); (p(2) + d)/sct_p.kap - p(8) + p(1) + p(4); p(8)];
f_pt   = @(Vap_, Vfld_, d) f_vref([rand; Vap_; Vfld_; 0.1*rand; f_V(); 0; 0.1*rand], d);
Vap_in  = @() r_in(sct_p.Vap_min, sct_p.Vap_max);
Vfld_in = @() r_in(sct_p.Vfld_min, sct_p.Vfld_max);

c_region = {
    "inside the limits",                  f_param(sct_p), @() f_pt(Vap_in(), Vfld_in(), randn), sym_rhs
    "Vap = Vap_max, pushed out (frozen)",  f_param(sct_p), @() f_pt(sct_p.Vap_max, Vfld_in(),  r_pos()), f_freeze(2)
    "Vap = Vap_max, pulled back",          f_param(sct_p), @() f_pt(sct_p.Vap_max, Vfld_in(), -r_pos()), sym_rhs
    "Vap = Vap_min, pushed out (frozen)",  f_param(sct_p), @() f_pt(sct_p.Vap_min, Vfld_in(), -r_pos()), f_freeze(2)
    "Vap = Vap_min, pulled back",          f_param(sct_p), @() f_pt(sct_p.Vap_min, Vfld_in(),  r_pos()), sym_rhs
    % Vfld の制限: dx3 = Vap - g_ex(Vfld) の符号を Vap で決める (Vap は自身の制限の内側)
    "Vfld = Vfld_max, pushed out (frozen)", f_param(sct_p), @() f_pt(g_ex(sct_p.Vfld_max) + r_pos(), sct_p.Vfld_max, randn), f_freeze(3)
    "Vfld = Vfld_max, pulled back",         f_param(sct_p), @() f_pt(g_ex(sct_p.Vfld_max) - r_pos(), sct_p.Vfld_max, randn), sym_rhs
    "Vfld = Vfld_min, pushed out (frozen)", f_param(sct_p), @() f_pt(g_ex(sct_p.Vfld_min) - r_pos(), sct_p.Vfld_min, randn), f_freeze(3)
    "Vfld = Vfld_min, pulled back",         f_param(sct_p), @() f_pt(g_ex(sct_p.Vfld_min) + r_pos(), sct_p.Vfld_min, randn), sym_rhs
    % Limiter = false: 両方の制限の外で、さらに外へ向かっても止めない
    "Limiter = false, beyond the limits",  f_param(sct_nolim), ...
        @() f_pt(sct_p.Vap_max + 0.2 + r_pos(), sct_p.Vfld_max + r_pos(), r_pos()), sym_rhs
    };
c_case(end+1, :) = {"AVR_DC1", ...
    struct(fcn_dx=@controller.avr.AVR_DC1.fcn_dx, fcn_y=@controller.avr.AVR_DC1.fcn_y, ...
           Jacobi_dx=@controller.avr.AVR_DC1.Jacobi_dx, Jacobi_Y=@controller.avr.AVR_DC1.Jacobi_Y, nx=4), ...
    [Vtr; Vap; Vfld; Vst; Vre; Vim; Vref; Vpss], c_region};

%% AVR_ST1
% 状態 x = [Vtr; Vap; Vst]、入力 u = [Vref; Vpss; Ifield]、出力 y = Vap (出力の制限の内側)
syms Vtr Vap Vst Vref Vpss Ifield real
sv_para = ["ttr"; "Vap_max"; "Vap_min"; "kap"; "tap"; "kst"; "tst"; "Limiter"; "gamma_max"; "gamma_min"; "k0"];
sct_p = struct(ttr=0, Vap_max=5, Vap_min=-5, kap=30, tap=0.05, kst=0, tst=0, Limiter=true, ...
               gamma_max=Inf, gamma_min=-Inf, k0=0);
f_param = @(sct) arrayfun(@(s) double(sct.(s)), sv_para);
sct_static = sct_p;          % 静的な増幅器
sct_static.tap = 0;
sct_out = sct_p;             % 出力の制限
sct_out.gamma_max = 1.5;
sct_out.gamma_min = -1;
sct_out.k0        = 0.2;
sct_cross = sct_p;           % 交差した出力の制限 (下限が上限より大きい)
sct_cross.gamma_max = 0.6;
sct_cross.gamma_min = 0.5;
sct_cross.k0        = 1;
sct_nolim = sct_out;         % 出力の制限があっても Limiter = false なら無視する
sct_nolim.Limiter = false;

% 制限のないモデル
Vcom    = Vref + Vpss - Vtr - Vst;
sym_rhs = [-Vtr + Vabs; -Vap + sct_p.kap*Vcom; -Vst; Vap];
f_freeze = @(iv) sym_rhs .* double(~ismember((1:4)', iv));

% 点 [Vtr; Vap; Vst; Vre; Vim; Vref; Vpss; Ifield]。Vref は kap*Vcom が w になるように決める
f_vref = @(p, w) [p(1:5); w/sct_p.kap - p(7) + p(1) + p(3); p(7:8)];
f_pt   = @(Vap_, w) f_vref([rand; Vap_; 0.1*rand; f_V(); 0; 0.1*rand; 0.5 + 0.5*rand], w);
f_Vap  = @(p, Vap_) [p(1); Vap_; p(3:8)];                    % Vap だけを置き換える
g_up   = @(sct, p) sct.gamma_max*norm(p(4:5)) - sct.k0*p(8);  % 出力の上限 gamma_max*|V| - k0*Ifield
g_lo   = @(sct, p) sct.gamma_min*norm(p(4:5));                % 出力の下限 gamma_min*|V|
Vap_in = @() r_in(sct_p.Vap_min, sct_p.Vap_max);
p_out  = @() f_pt(0, randn);                                 % 出力の制限の点の元 (Vap は後で置き換える)
f_between = @(p) f_Vap(p, r_in(g_lo(sct_out, p), g_up(sct_out, p)));
f_above   = @(p) f_Vap(p, g_up(sct_out, p) + r_pos());
f_below   = @(p) f_Vap(p, g_lo(sct_out, p) - r_pos());

c_region = {
    "inside the limits",                  f_param(sct_p), @() f_pt(Vap_in(), 0), sym_rhs
    "Vap = Vap_max, pushed out (frozen)",  f_param(sct_p), @() f_pt(sct_p.Vap_max, sct_p.Vap_max + r_pos()), f_freeze(2)
    "Vap = Vap_max, pulled back",          f_param(sct_p), @() f_pt(sct_p.Vap_max, sct_p.Vap_max - r_pos()), sym_rhs
    "Vap = Vap_min, pushed out (frozen)",  f_param(sct_p), @() f_pt(sct_p.Vap_min, sct_p.Vap_min - r_pos()), f_freeze(2)
    "Vap = Vap_min, pulled back",          f_param(sct_p), @() f_pt(sct_p.Vap_min, sct_p.Vap_min + r_pos()), sym_rhs
    % Limiter = false: Vap と出力の制限をどちらも無視する
    "Limiter = false, beyond the limits",  f_param(sct_nolim), ...
        @() f_pt(sct_p.Vap_max + r_pos(), sct_p.Vap_max + 2 + r_pos()), sym_rhs
    % tap = 0: dx2 = -Vap + max(min(kap*Vcom, Vap_max), Vap_min)
    "tap = 0, kap*Vcom inside the limits", f_param(sct_static), @() f_pt(randn, Vap_in()), sym_rhs
    "tap = 0, kap*Vcom above Vap_max",     f_param(sct_static), @() f_pt(randn, sct_p.Vap_max + r_pos()), ...
        [sym_rhs(1); -Vap + sct_p.Vap_max; sym_rhs(3:4)]
    "tap = 0, kap*Vcom below Vap_min",     f_param(sct_static), @() f_pt(randn, sct_p.Vap_min - r_pos()), ...
        [sym_rhs(1); -Vap + sct_p.Vap_min; sym_rhs(3:4)]
    % 出力の制限 (Vap は自身の制限の内側なので止まらない)
    "output between its limits",           f_param(sct_out), @() f_between(p_out()), sym_rhs
    "output at the upper limit",           f_param(sct_out), @() f_above(p_out()), ...
        [sym_rhs(1:3); sct_out.gamma_max*Vabs - sct_out.k0*Ifield]
    "output at the lower limit",           f_param(sct_out), @() f_below(p_out()), ...
        [sym_rhs(1:3); sct_out.gamma_min*Vabs]
    "output limits crossed (lower wins)",  f_param(sct_cross), @() f_Vap(p_out(), randn), ...
        [sym_rhs(1:3); sct_cross.gamma_min*Vabs]
    };
c_case(end+1, :) = {"AVR_ST1", ...
    struct(fcn_dx=@controller.avr.AVR_ST1.fcn_dx, fcn_y=@controller.avr.AVR_ST1.fcn_y, ...
           Jacobi_dx=@controller.avr.AVR_ST1.Jacobi_dx, Jacobi_Y=@controller.avr.AVR_ST1.Jacobi_Y, nx=3), ...
    [Vtr; Vap; Vst; Vre; Vim; Vref; Vpss; Ifield], c_region};

%% PSS1
% 状態 x = [xiWS; xi1; xi2]、入力 u = omega、出力 y = Vpss (vpl を [Vpss_min, Vpss_max] に飽和)
syms xiWS xi1 xi2 omega real
sv_para = ["kpss"; "tWS"; "tn1"; "td1"; "tn2"; "td2"; "Vpss_min"; "Vpss_max"];
sct_p = struct(kpss=20, tWS=10, tn1=0.05, td1=0.02, tn2=3.00, td2=5.40, Vpss_min=-0.1, Vpss_max=0.1);
f_param = @(sct) arrayfun(@(s) double(sct.(s)), sv_para);
sct_id = sct_p;              % tn1 = td1 = 0 のブロック (飽和なし)
sct_id.tn1 = 0;
sct_id.td1 = 0;
sct_id.Vpss_min = -Inf;
sct_id.Vpss_max = Inf;
sct_lag = sct_p;             % tn2 = 0 のブロック (飽和なし)
sct_lag.tn2 = 0;
sct_lag.Vpss_min = -Inf;
sct_lag.Vpss_max = Inf;

% ウォッシュアウトフィルタ
vWS = sct_p.kpss*omega - xiWS;
% 位相進み補償器 (進み遅れブロック 2 つ)
v1  = sct_p.tn1*(vWS - xi1)/sct_p.td1;
vpl = sct_p.tn2*(v1 - xi2)/sct_p.td2;
sym_rhs = [-xiWS + sct_p.kpss*omega; -xi1 + (1 - sct_p.td1/sct_p.tn1)*vWS; -xi2 + (1 - sct_p.td2/sct_p.tn2)*v1; vpl];
% tn1 = td1 = 0: クラスは tn1 = td1 = 1 として扱う (a1 = 0、v1 = vWS - xi1。質量行列の行が 0 なので xi1 = 0 で恒等)
v1_id  = vWS - xi1;
rhs_id = [sym_rhs(1); -xi1; -xi2 + (1 - sct_p.td2/sct_p.tn2)*v1_id; sct_p.tn2*(v1_id - xi2)/sct_p.td2];
% tn2 = 0: 1 次遅れ td2*dxi2 = -xi2 + v1、出力 vpl = xi2
rhs_lag = [sym_rhs(1:2); -xi2 + v1; xi2];

% 点 [xiWS; xi1; xi2; Vre; Vim; omega]。xi2 は vpl が目標値になるように決める
f_vpl = @(p, target) [p(1:2); sct_p.tn1*(sct_p.kpss*p(6) - p(1) - p(2))/sct_p.td1 - target*sct_p.td2/sct_p.tn2; p(4:6)];
f_pt  = @() [0.1*randn(3,1); f_V(); 0.01*randn];

c_region = {
    "vpl inside the limits",       f_param(sct_p), @() f_vpl(f_pt(), r_in(sct_p.Vpss_min, sct_p.Vpss_max)), sym_rhs
    "vpl above Vpss_max",          f_param(sct_p), @() f_vpl(f_pt(), sct_p.Vpss_max + r_pos()), [sym_rhs(1:3); sct_p.Vpss_max]
    "vpl below Vpss_min",          f_param(sct_p), @() f_vpl(f_pt(), sct_p.Vpss_min - r_pos()), [sym_rhs(1:3); sct_p.Vpss_min]
    "tn1 = td1 = 0 (identity)",    f_param(sct_id),  f_pt, rhs_id
    "tn2 = 0 (first-order lag)",   f_param(sct_lag), f_pt, rhs_lag
    };
c_case(end+1, :) = {"PSS1", ...
    struct(fcn_dx=@controller.pss.PSS1.fcn_dx, fcn_y=@controller.pss.PSS1.fcn_y, ...
           Jacobi_dx=@controller.pss.PSS1.Jacobi_dx, Jacobi_Y=@controller.pss.PSS1.Jacobi_Y, nx=3), ...
    [xiWS; xi1; xi2; Vre; Vim; omega], c_region};

%% 比較
% 領域ごとに n_point 個の点で、クラスの [fcn_dx; fcn_y] と [Jacobi_dx; Jacobi_Y] を期待値と比べる
sv_result = ["PASS", "FAIL"];
fprintf("%-8s  %-40s  %-6s  %-9s  %-9s\n", "Class", "Region", "Result", "rhs err", "jac err");
n_fail  = 0;
n_check = 0;
for i_case = 1:size(c_case, 1)
    [s_class, sct_class, sym_var, c_region] = c_case{i_case, :};
    nx    = sct_class.nx;
    n_var = numel(sym_var);
    for i_region = 1:size(c_region, 1)
        [s_region, rv_param, f_point, sym_expr] = c_region{i_region, :};
        n_row = numel(sym_expr);
        f_rhs = matlabFunction(sym_expr, Vars={sym_var});
        f_jac = matlabFunction(jacobian(sym_expr, sym_var), Vars={sym_var});
        d_rhs = 0;          % [f; y] の最大の相対誤差
        d_jac = 0;          % ヤコビアンの最大の相対誤差
        d_max = -1;
        rv_worst = zeros(n_var, 1);
        for k = 1:n_point
            p = f_point();
            x = p(1:nx);
            V = p(nx+(1:2));
            u = p(nx+3:end);
            [Axx, Bxv, Bxu] = sct_class.Jacobi_dx(0, x, V, u, rv_param, omega0);
            [Cyx, Dyv, Dyu] = sct_class.Jacobi_Y(0, x, V, u, rv_param, omega0);
            rv_class  = [sct_class.fcn_dx(0, x, V, u, rv_param, omega0); sct_class.fcn_y(0, x, V, u, rv_param, omega0)];
            mat_class = [Axx, Bxv, Bxu; Cyx, Dyv, Dyu];
            rv_exp  = reshape(double(f_rhs(p)), n_row, 1);
            mat_exp = reshape(double(f_jac(p)), n_row, n_var);
            rv_e_rhs = abs(rv_class - rv_exp) ./ max(1, abs(rv_exp));
            rv_e_jac = abs(mat_class(:) - mat_exp(:)) ./ max(1, abs(mat_exp(:)));
            % 期待値やクラスの値が Inf や NaN (dirac など) のときは不一致とする (max は NaN を無視するため)
            rv_e_rhs(~isfinite(rv_e_rhs)) = Inf;
            rv_e_jac(~isfinite(rv_e_jac)) = Inf;
            d_rhs = max([d_rhs; rv_e_rhs]);
            d_jac = max([d_jac; rv_e_jac]);
            if max([rv_e_rhs; rv_e_jac]) > d_max
                d_max    = max([rv_e_rhs; rv_e_jac]);
                rv_worst = p;
            end
        end
        tf_pass = d_rhs <= tol && d_jac <= tol;
        n_check = n_check + 1;
        n_fail  = n_fail + ~tf_pass;
        fprintf("%-8s  %-40s  %-6s  %9.2e  %9.2e\n", s_class, s_region, sv_result(2 - tf_pass), d_rhs, d_jac);
        if ~tf_pass
            fprintf("          worst point [x; V; u] = [%s]\n", strjoin(compose("%.6g", rv_worst), "; "));
        end
    end
end
fprintf("%d of %d checks passed.\n", n_check - n_fail, n_check);
if n_fail > 0
    error("validate:Mismatch", "%d of %d controller checks failed.", n_fail, n_check)
end
