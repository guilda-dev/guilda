syms t     
syms xiWS xi1 xi2
syms Vre Vim     
syms omega

kpss      = 20;
tWS       = 10;
tn1       = 0.05;
td1       = 0.02;
tn2       = 3.00;
td2       = 5.40;
Vpss_min  = -inf;
Vpss_max  = inf;
    
x = [xiWS; xi1; xi2];
u = omega;
% ウォッシュアウトフィルタ
dx1 = -xiWS + kpss*omega;
vWS = kpss*omega - xiWS;
% 位相進み補償器
dx2 = -xi1 + (1-td1/tn1) * vWS;
v1  = tn1*(vWS-xi1)/td1;
% 飽和
dx3  = -xi2 + (1-td2/tn2) * v1;
vpl  = tn2*(v1-xi2)/td2;
Vpss = max(min(vpl, Vpss_max), Vpss_min);

dx = [dx1; dx2; dx3];

para = [kpss, tWS, tn1, td1, tn2, td2, Vpss_min, Vpss_max];


step = heaviside(vpl - Vpss_min) - heaviside(vpl - Vpss_max);
V    = [Vre; Vim];

jac = jacobian([dx;vpl], [x;V]);
jac = matlabFunction(jac, Vars={[x;V;u]});

for i=1:10000
    x_ = rand([3,1]);
    V_ = rand([2,1]);
    u_  = rand([1,1]);

    dif = zeros(1000*4,5);
    dif(i*(1:4), :) = jac([x_;V_;u_]) - pss_jacobian([x_;V_], u_, para, Vpss_max, Vpss_min);
end

all(dif < 1e-14)

function J = pss_jacobian(x, u, param, Vpss_max, Vpss_min)
    % パラメータの展開
    kpss = param(1);     
    tn1 = param(3);
    td1 = param(4);
    tn2 = param(5);
    td2 = param(6);
    
    % 状態変数の展開
    xiWS = x(1);
    xi1  = x(2);
    xi2  = x(3);
    % Vre, Vim はこの系のdxには寄与しないが、ヤコビアンのサイズ維持のため参照
    
    % 中間変数の計算（飽和判定用）
    omega = u;
    vWS = kpss * omega - xiWS;
    v1  = tn1 * (vWS - xi1) / td1;
    vpl = tn2 * (v1 - xi2) / td2;
    
    % 飽和フラグ (飽和している場合は微係数は0)
    if vpl > Vpss_max || vpl < Vpss_min
        S = 0;
    else
        S = 1;
    end

    % ヤコビ行列の初期化 (4x5)
    J = zeros(4, 5);

    % --- Row 1: df1/dx (dx1) ---
    J(1,1) = -1;
    
    % --- Row 2: df2/dx (dx2) ---
    J(2,1) = -(1 - td1/tn1);
    J(2,2) = -1;
    
    % --- Row 3: df3/dx (dx3) ---
    % dx3 = -xi2 + (1-td2/tn2) * v1
    % v1 = (tn1/td1)*(kpss*omega - xiWS - xi1)
    J(3,1) = (1 - td2/tn2) * (-tn1/td1);
    J(3,2) = (1 - td2/tn2) * (-tn1/td1);
    J(3,3) = -1;
    
    % --- Row 4: dVpss/dx (Vpss) ---
    % vpl = (tn2/td2) * (v1 - xi2)
    % v1  = (tn1/td1) * (kpss*omega - xiWS - xi1)
    dv1_dxiWS = -tn1/td1;
    dv1_dxi1  = -tn1/td1;
    
    J(4,1) = S * (tn2/td2) * dv1_dxiWS;
    J(4,2) = S * (tn2/td2) * dv1_dxi1;
    J(4,3) = S * (-tn2/td2);
    
    % 第4列(Vre), 第5列(Vim) はすべて0のまま
end