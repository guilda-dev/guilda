% Developer script: needs no toolbox. It checks hand-written controller Jacobians against
% central finite differences and is not part of the GUILDA runtime.
%
% 制御器のクラスの静的メソッド fcn_dx・fcn_y・Jacobi_dx・Jacobi_Y を直接呼び、制限の領域ごとに
% ランダムな点で次の 2 つを確かめます。
%   rhs: クラスの [fcn_dx; fcn_y] が、その領域の規則をこのスクリプトで別に書いた式と一致する。
%        止まる状態の行は厳密に 0 である。
%   jac: クラスの [Jacobi_dx; Jacobi_Y] = d[f; y]/d[x; V; u] が、クラスの [fcn_dx; fcn_y] の中心差分と
%        一致する。止まる状態の行は厳密に 0 である (差分は取らない)。
% 点は切り替えの境界から離し (止まる領域と境界の上で戻る領域だけは境界の上)、差分の刻みは境界までの
% 距離より十分小さくして、差分が 1 つの領域に収まるようにします。
%   controller.avr.AVR_DC1 : Vap と Vfld の non-windup 制限 (制限に達し、さらに外へ向かう間は止める)
%   controller.avr.AVR_ST1 : Vap の non-windup 制限、tap = 0 の静的な増幅器の飽和、出力の制限
%   controller.pss.PSS1    : 出力 Vpss の飽和、tn = td = 0 と tn = 0 の進み遅れブロック
% 実行: GUILDA を起動したあと controller.validate (パッケージの中のスクリプトなので run では呼べません)
% 領域ごとに PASS / FAIL を表示し、1 つでも FAIL があれば最後に error にします。

rng(0)              % 再現できる乱数
n_point = 200;      % 領域ごとの点の数
h_step  = 1e-6;     % 中心差分の刻み (変数ごとに max(1, |値|) 倍)
tol_rhs = 1e-12;    % rhs の許容誤差 (|差| / max(1, |期待値|))
tol_jac = 1e-6;     % jac の許容誤差 (|差| / max(1, |差分|))
omega0  = 60;       % [Hz] 基準周波数 (どの制御器も使わない)

f_V   = @() [0.9 + 0.2*rand; 0.4*rand - 0.2];         % 端子電圧 [real; imag] (|V| は 1 前後)
r_in  = @(lo, hi) lo + (hi - lo)*(0.05 + 0.9*rand);   % (lo, hi) の内側の乱数 (両端から 5% 離す)
r_pos = @() 0.1 + rand;                               % 正の乱数 (境界から離す量)

% c_case の各行: {制御器の名前, クラスの静的メソッドと状態の数, 領域の cell}
% 領域の cell の各行: {領域の名前, パラメータ (sv_para の順), 点 [x; V; u] を返す関数,
%                      期待する [f; y] を点から返す関数, 止まる状態の行}
c_case = cell(0, 3);

%% AVR_DC1
% 状態 x = [Vtr; Vap; Vfld; Vst]、入力 u = [Vref; Vpss]、出力 y = Vfld
% 点 p = [Vtr; Vap; Vfld; Vst; Vre; Vim; Vref; Vpss]
sv_para = ["ttr"; "Vap_max"; "Vap_min"; "kap"; "tap"; "aex1"; "aex2"; "tex"; "bex"; "kst"; "tst"; "Vfld_max"; "Vfld_min"; "Limiter"];
sct_p = struct(ttr=0.01, Vap_max=5, Vap_min=-5, kap=20, tap=0.2, aex1=1, aex2=0.0039, tex=0.314, ...
               bex=1.555, kst=0.063, tst=0.35, Vfld_max=2, Vfld_min=-2, Limiter=true);
f_param = @(sct) arrayfun(@(s) double(sct.(s)), sv_para);
sct_nolim = sct_p;
sct_nolim.Limiter = false;

% 制限のないモデル: 計測用変圧器、増幅器 (コンパレータ Vcom = Vref + Vpss - Vtr - Vst)、励磁器、安定化回路、出力
g_ex  = @(v) (sct_p.aex1 + sct_p.aex2*exp(sct_p.bex*v))*v;   % 励磁器の飽和項 (dx3 = Vap - g_ex(Vfld))
f_rhs = @(p) [-p(1) + norm(p(5:6)); -p(2) + sct_p.kap*(p(7) + p(8) - p(1) - p(4)); p(2) - g_ex(p(3)); -p(4); p(3)];
% 止まる状態の行を 0 にした式
f_freeze = @(iv) @(p) f_rhs(p) .* ~ismember((1:5)', iv);

% Vref は dx2 = -Vap + kap*Vcom が d になるように決める
f_vref = @(p, d) [p(1:6); (p(2) + d)/sct_p.kap - p(8) + p(1) + p(4); p(8)];
f_pt   = @(Vap_, Vfld_, d) f_vref([rand; Vap_; Vfld_; 0.1*rand; f_V(); 0; 0.1*rand], d);
Vap_in  = @() r_in(sct_p.Vap_min, sct_p.Vap_max);
Vfld_in = @() r_in(sct_p.Vfld_min, sct_p.Vfld_max);

c_region = {
    "inside the limits",                    f_param(sct_p), @() f_pt(Vap_in(), Vfld_in(), randn), f_rhs, []
    "Vap = Vap_max, pushed out (frozen)",   f_param(sct_p), @() f_pt(sct_p.Vap_max, Vfld_in(),  r_pos()), f_freeze(2), 2
    "Vap = Vap_max, pulled back",           f_param(sct_p), @() f_pt(sct_p.Vap_max, Vfld_in(), -r_pos()), f_rhs, []
    "Vap = Vap_min, pushed out (frozen)",   f_param(sct_p), @() f_pt(sct_p.Vap_min, Vfld_in(), -r_pos()), f_freeze(2), 2
    "Vap = Vap_min, pulled back",           f_param(sct_p), @() f_pt(sct_p.Vap_min, Vfld_in(),  r_pos()), f_rhs, []
    % Vfld の制限: dx3 = Vap - g_ex(Vfld) の符号を Vap で決める (Vap は自身の制限の内側)
    "Vfld = Vfld_max, pushed out (frozen)", f_param(sct_p), @() f_pt(g_ex(sct_p.Vfld_max) + r_pos(), sct_p.Vfld_max, randn), f_freeze(3), 3
    "Vfld = Vfld_max, pulled back",         f_param(sct_p), @() f_pt(g_ex(sct_p.Vfld_max) - r_pos(), sct_p.Vfld_max, randn), f_rhs, []
    "Vfld = Vfld_min, pushed out (frozen)", f_param(sct_p), @() f_pt(g_ex(sct_p.Vfld_min) - r_pos(), sct_p.Vfld_min, randn), f_freeze(3), 3
    "Vfld = Vfld_min, pulled back",         f_param(sct_p), @() f_pt(g_ex(sct_p.Vfld_min) + r_pos(), sct_p.Vfld_min, randn), f_rhs, []
    % Limiter = false: 両方の制限の外で、さらに外へ向かっても止めない
    "Limiter = false, beyond the limits",   f_param(sct_nolim), ...
        @() f_pt(sct_p.Vap_max + 0.2 + r_pos(), sct_p.Vfld_max + r_pos(), r_pos()), f_rhs, []
    };
c_case(end+1, :) = {"AVR_DC1", ...
    struct(fcn_dx=@controller.avr.AVR_DC1.fcn_dx, fcn_y=@controller.avr.AVR_DC1.fcn_y, ...
           Jacobi_dx=@controller.avr.AVR_DC1.Jacobi_dx, Jacobi_Y=@controller.avr.AVR_DC1.Jacobi_Y, nx=4), c_region};

%% AVR_ST1
% 状態 x = [Vtr; Vap; Vst]、入力 u = [Vref; Vpss; Ifield]、出力 y = Vap (出力の制限の内側)
% 点 p = [Vtr; Vap; Vst; Vre; Vim; Vref; Vpss; Ifield]
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
kVcom = @(p) sct_p.kap*(p(6) + p(7) - p(1) - p(3));    % kap*Vcom
f_rhs = @(p) [-p(1) + norm(p(4:5)); -p(2) + kVcom(p); -p(3); p(2)];
f_freeze = @(iv) @(p) f_rhs(p) .* ~ismember((1:4)', iv);
g_up  = @(sct, p) sct.gamma_max*norm(p(4:5)) - sct.k0*p(8);  % 出力の上限 gamma_max*|V| - k0*Ifield
g_lo  = @(sct, p) sct.gamma_min*norm(p(4:5));                % 出力の下限 gamma_min*|V|

% Vref は kap*Vcom が w になるように決める
f_vref = @(p, w) [p(1:5); w/sct_p.kap - p(7) + p(1) + p(3); p(7:8)];
f_pt   = @(Vap_, w) f_vref([rand; Vap_; 0.1*rand; f_V(); 0; 0.1*rand; 0.5 + 0.5*rand], w);
f_Vap  = @(p, Vap_) [p(1); Vap_; p(3:8)];                    % Vap だけを置き換える
Vap_in = @() r_in(sct_p.Vap_min, sct_p.Vap_max);
p_out  = @() f_pt(0, randn);                                 % 出力の制限の点の元 (Vap は後で置き換える)
f_between = @(p) f_Vap(p, r_in(g_lo(sct_out, p), g_up(sct_out, p)));
f_above   = @(p) f_Vap(p, g_up(sct_out, p) + r_pos());
f_below   = @(p) f_Vap(p, g_lo(sct_out, p) - r_pos());

c_region = {
    "inside the limits",                   f_param(sct_p), @() f_pt(Vap_in(), 0), f_rhs, []
    "Vap = Vap_max, pushed out (frozen)",  f_param(sct_p), @() f_pt(sct_p.Vap_max, sct_p.Vap_max + r_pos()), f_freeze(2), 2
    "Vap = Vap_max, pulled back",          f_param(sct_p), @() f_pt(sct_p.Vap_max, sct_p.Vap_max - r_pos()), f_rhs, []
    "Vap = Vap_min, pushed out (frozen)",  f_param(sct_p), @() f_pt(sct_p.Vap_min, sct_p.Vap_min - r_pos()), f_freeze(2), 2
    "Vap = Vap_min, pulled back",          f_param(sct_p), @() f_pt(sct_p.Vap_min, sct_p.Vap_min + r_pos()), f_rhs, []
    % Limiter = false: Vap と出力の制限をどちらも無視する
    "Limiter = false, beyond the limits",  f_param(sct_nolim), ...
        @() f_pt(sct_p.Vap_max + r_pos(), sct_p.Vap_max + 2 + r_pos()), f_rhs, []
    % tap = 0: dx2 = -Vap + max(min(kap*Vcom, Vap_max), Vap_min)
    "tap = 0, kap*Vcom inside the limits", f_param(sct_static), @() f_pt(randn, Vap_in()), f_rhs, []
    "tap = 0, kap*Vcom above Vap_max",     f_param(sct_static), @() f_pt(randn, sct_p.Vap_max + r_pos()), ...
        @(p) f_rhs(p) .* [1; 0; 1; 1] + [0; -p(2) + sct_p.Vap_max; 0; 0], []
    "tap = 0, kap*Vcom below Vap_min",     f_param(sct_static), @() f_pt(randn, sct_p.Vap_min - r_pos()), ...
        @(p) f_rhs(p) .* [1; 0; 1; 1] + [0; -p(2) + sct_p.Vap_min; 0; 0], []
    % 出力の制限 (Vap は自身の制限の内側なので止まらない)
    "output between its limits",           f_param(sct_out), @() f_between(p_out()), f_rhs, []
    "output at the upper limit",           f_param(sct_out), @() f_above(p_out()), ...
        @(p) f_rhs(p) .* [1; 1; 1; 0] + [0; 0; 0; g_up(sct_out, p)], []
    "output at the lower limit",           f_param(sct_out), @() f_below(p_out()), ...
        @(p) f_rhs(p) .* [1; 1; 1; 0] + [0; 0; 0; g_lo(sct_out, p)], []
    "output limits crossed (lower wins)",  f_param(sct_cross), @() f_Vap(p_out(), randn), ...
        @(p) f_rhs(p) .* [1; 1; 1; 0] + [0; 0; 0; g_lo(sct_cross, p)], []
    };
c_case(end+1, :) = {"AVR_ST1", ...
    struct(fcn_dx=@controller.avr.AVR_ST1.fcn_dx, fcn_y=@controller.avr.AVR_ST1.fcn_y, ...
           Jacobi_dx=@controller.avr.AVR_ST1.Jacobi_dx, Jacobi_Y=@controller.avr.AVR_ST1.Jacobi_Y, nx=3), c_region};

%% PSS1
% 状態 x = [xiWS; xi1; xi2]、入力 u = omega、出力 y = Vpss (vpl を [Vpss_min, Vpss_max] に飽和)
% 点 p = [xiWS; xi1; xi2; Vre; Vim; omega]
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

% ウォッシュアウトフィルタ vWS と、進み遅れブロック (tn, td) の出力 tn*(v - xi)/td、状態の式 -xi + (1 - td/tn)*v
vWS  = @(p) sct_p.kpss*p(6) - p(1);
v1   = @(p) sct_p.tn1*(vWS(p) - p(2))/sct_p.td1;
vpl  = @(p) sct_p.tn2*(v1(p) - p(3))/sct_p.td2;
f_rhs = @(p) [vWS(p); -p(2) + (1 - sct_p.td1/sct_p.tn1)*vWS(p); -p(3) + (1 - sct_p.td2/sct_p.tn2)*v1(p); vpl(p)];
% tn1 = td1 = 0: クラスは tn1 = td1 = 1 として扱う (a1 = 0、v1 = vWS - xi1。質量行列の行が 0 なので xi1 = 0 で恒等)
v1_id  = @(p) vWS(p) - p(2);
f_id   = @(p) [vWS(p); -p(2); -p(3) + (1 - sct_p.td2/sct_p.tn2)*v1_id(p); sct_p.tn2*(v1_id(p) - p(3))/sct_p.td2];
% tn2 = 0: 1 次遅れ td2*dxi2 = -xi2 + v1、出力 vpl = xi2
f_lag  = @(p) [vWS(p); -p(2) + (1 - sct_p.td1/sct_p.tn1)*vWS(p); -p(3) + v1(p); p(3)];

% xi2 は vpl が目標値になるように決める
f_vpl = @(p, target) [p(1:2); v1(p) - target*sct_p.td2/sct_p.tn2; p(4:6)];
f_pt  = @() [0.1*randn(3,1); f_V(); 0.01*randn];

c_region = {
    "vpl inside the limits",       f_param(sct_p), @() f_vpl(f_pt(), r_in(sct_p.Vpss_min, sct_p.Vpss_max)), f_rhs, []
    "vpl above Vpss_max",          f_param(sct_p), @() f_vpl(f_pt(), sct_p.Vpss_max + r_pos()), ...
        @(p) f_rhs(p) .* [1; 1; 1; 0] + [0; 0; 0; sct_p.Vpss_max], []
    "vpl below Vpss_min",          f_param(sct_p), @() f_vpl(f_pt(), sct_p.Vpss_min - r_pos()), ...
        @(p) f_rhs(p) .* [1; 1; 1; 0] + [0; 0; 0; sct_p.Vpss_min], []
    "tn1 = td1 = 0 (identity)",    f_param(sct_id),  f_pt, f_id, []
    "tn2 = 0 (first-order lag)",   f_param(sct_lag), f_pt, f_lag, []
    };
c_case(end+1, :) = {"PSS1", ...
    struct(fcn_dx=@controller.pss.PSS1.fcn_dx, fcn_y=@controller.pss.PSS1.fcn_y, ...
           Jacobi_dx=@controller.pss.PSS1.Jacobi_dx, Jacobi_Y=@controller.pss.PSS1.Jacobi_Y, nx=3), c_region};

%% 比較
sv_result = ["PASS", "FAIL"];
fprintf("%-8s  %-40s  %-6s  %-9s  %-9s\n", "Class", "Region", "Result", "rhs err", "jac err");
n_fail  = 0;
n_check = 0;
for i_case = 1:size(c_case, 1)
    [s_class, sct_class, c_region] = c_case{i_case, :};
    nx = sct_class.nx;
    % 点 p = [x; V; u] でのクラスの [f; y]
    f_class = @(p, rv_param) [sct_class.fcn_dx(0, p(1:nx), p(nx+(1:2)), p(nx+3:end), rv_param, omega0); ...
                              sct_class.fcn_y( 0, p(1:nx), p(nx+(1:2)), p(nx+3:end), rv_param, omega0)];
    for i_region = 1:size(c_region, 1)
        [s_region, rv_param, f_point, f_expect, iv_frozen] = c_region{i_region, :};
        d_rhs = 0;          % rhs の最大の相対誤差
        d_jac = 0;          % jac の最大の相対誤差
        d_max = -1;
        rv_worst = [];
        for k = 1:n_point
            p = f_point();
            x = p(1:nx);
            V = p(nx+(1:2));
            u = p(nx+3:end);
            % rhs: クラスの式と規則の式。止まる行は厳密に 0
            rv_class = f_class(p, rv_param);
            rv_exp   = f_expect(p);
            rv_e_rhs = abs(rv_class - rv_exp) ./ max(1, abs(rv_exp));
            rv_e_rhs(any(rv_class(iv_frozen) ~= 0)) = Inf;
            % jac: クラスのヤコビアンと、クラスの [f; y] の中心差分。止まる行は厳密に 0
            [Axx, Bxv, Bxu] = sct_class.Jacobi_dx(0, x, V, u, rv_param, omega0);
            [Cyx, Dyv, Dyu] = sct_class.Jacobi_Y(0, x, V, u, rv_param, omega0);
            mat_class = [Axx, Bxv, Bxu; Cyx, Dyv, Dyu];
            mat_fd = zeros(size(mat_class));
            for j = 1:numel(p)
                rv_h = zeros(size(p));
                rv_h(j) = h_step*max(1, abs(p(j)));
                mat_fd(:, j) = (f_class(p + rv_h, rv_param) - f_class(p - rv_h, rv_param)) / (2*rv_h(j));
            end
            mat_fd(iv_frozen, :) = 0;
            rv_e_jac = abs(mat_class(:) - mat_fd(:)) ./ max(1, abs(mat_fd(:)));
            rv_e_jac(any(mat_class(iv_frozen, :) ~= 0, "all")) = Inf;
            % Inf や NaN は不一致とする (max は NaN を無視するため)
            rv_e_rhs(~isfinite(rv_e_rhs)) = Inf;
            rv_e_jac(~isfinite(rv_e_jac)) = Inf;
            d_rhs = max([d_rhs; rv_e_rhs]);
            d_jac = max([d_jac; rv_e_jac]);
            if max([rv_e_rhs; rv_e_jac]) > d_max
                d_max    = max([rv_e_rhs; rv_e_jac]);
                rv_worst = p;
            end
        end
        tf_pass = d_rhs <= tol_rhs && d_jac <= tol_jac;
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
