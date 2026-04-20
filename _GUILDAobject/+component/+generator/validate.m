D  = 2;  
Xd = 0.2;
Xq = 0.15;
     
syms delta
syms omega
syms Vre Vim

Pm  = 1.2;    
Vfd = 0.5;   

omega0 = 60;

V = [Vre;Vim];

Vdq = exp(1j*delta) * conj([1,1j]*V);
Vd  = imag(Vdq);
Vq  = real(Vdq);

Id  = (Vfd-Vq)/Xd;
Iq  = Vd/Xq;
Pout = Vq*Iq + Vd*Id;

ddelta = omega0 * omega;
domega = - D*omega - Pout + Pm;

Idq = Iq + 1j*Id;

I   = exp(1j*delta) * conj(Idq);

dx  = [ddelta; domega];

jac   = jacobian(dx, [delta;omega;Vre;Vim]);
jac_I = jacobian([real(I);imag(I)], [delta;omega;Vre;Vim]);


dif = zeros(1000*2, 4);
for i=1:1000
    x = rand([2,1]);
    V = [1,1j]*rand([2,1]);


    % dif(2*i+(1:2), :) = double( subs(jac, [delta;omega;Vre;Vim], [x;real(V);imag(V)]) )  -  calc_jacobian(x, [Pm;Vfd], V, [10; D; Xd; Xq], omega0);
    dif(2*i+(1:2), :) = double( subs(jac_I, [delta;omega;Vre;Vim], [x;real(V);imag(V)]) )  -  calc_current_jacobian(x, [Pm;Vfd], V, [10; D; Xd; Xq]);
end

all(dif < 1e-14)

% x = rand([2,1]);
% V = [1,1j]*rand([2,1]);
% double( subs(jac_I, [delta;omega;Vre;Vim], [x;real(V);imag(V)]) )
% calc_current_jacobian(x, [Pm;Vfd], V, [10; D; Xd; Xq])
% 
% double( subs(jac_I, [delta;omega;Vre;Vim], [x;real(V);imag(V)]) ) - calc_current_jacobian(x, [Pm;Vfd], V, [10; D; Xd; Xq])



function J = calc_jacobian(x, u, V, param, omega0)
    % 状態変数の展開
    delta = x(1);
    omega = x(2);
    % Vre = x(3); % 代数変数として扱う場合はこちら
    % Vim = x(4);
    
    % パラメータの展開
    D  = param(2);
    Xd = param(3);
    Xq = param(4);
    
    % 入力の展開
    Vfd = u(2);
    
    % Vの複素数成分（x(3), x(4)から取得する場合）
    Vre = real(V);
    Vim = imag(V);
    
    % dq軸電圧の計算（導出プロセスの再現）
    Vd = Vre*sin(delta) - Vim*cos(delta);
    Vq = Vre*cos(delta) + Vim*sin(delta);
    
    % 定数の定義
    K = (1/Xq - 1/Xd);
    
    % --- 偏微分の計算 ---
    
    % dPout/ddelta
    dP_ddelta = K * (Vq^2 - Vd^2) + (Vfd/Xd) * Vq;
    
    % dPout/dVre
    dP_dVre = K * (Vq*sin(delta) + Vd*cos(delta)) + (Vfd/Xd)*sin(delta);
    
    % dPout/dVim
    dP_dVim = K * (Vq*(-cos(delta)) + Vd*sin(delta)) - (Vfd/Xd)*cos(delta);
    
    % --- ヤコビアン行列の組み立て ---
    % f1 = ddelta, f2 = domega
    % x = [delta, omega, Vre, Vim]
    
    J = zeros(2, 4);
    
    % 1行目: d(ddelta)/dx
    J(1, 1) = 0;             % d(ddelta)/ddelta
    J(1, 2) = omega0;        % d(ddelta)/domega
    J(1, 3) = 0;             % d(ddelta)/dVre
    J(1, 4) = 0;             % d(ddelta)/dVim
    
    % 2行目: d(domega)/dx
    J(2, 1) = -dP_ddelta;    % d(domega)/ddelta
    J(2, 2) = -D;            % d(domega)/domega
    J(2, 3) = -dP_dVre;      % d(domega)/dVre
    J(2, 4) = -dP_dVim;      % d(domega)/dVim
end

function JI = calc_current_jacobian(x, u, V, param)
    % 状態変数とパラメータ
    delta = x(1);
    Vfd = u(2);
    Xd = param(3);
    Xq = param(4);
    
    Vre = real(V);
    Vim = imag(V);
    
    % dq軸電圧
    Vd = Vre*sin(delta) - Vim*cos(delta);
    Vq = Vre*cos(delta) + Vim*sin(delta);
    
    % 補助変数の微分 (dVd/d..., dVq/d...)
    % delta
    dVd_dd = Vq;
    dVq_dd = -Vd;
    % Vre
    dVd_dre = sin(delta);
    dVq_dre = cos(delta);
    % Vim
    dVd_dim = -cos(delta);
    dVq_dim = sin(delta);
    
    % 電流式の偏微分 (Ire, Iim)
    % JI(1,:) -> dIre/dx, JI(2,:) -> dIim/dx
    JI = zeros(2, 4);
    
    % delta に関する微分
    JI(1,1) = (dVd_dd/Xq)*cos(delta) - (Vd/Xq)*sin(delta) - (dVq_dd/Xd)*sin(delta) + ((Vfd-Vq)/Xd)*cos(delta);
    JI(2,1) = (dVd_dd/Xq)*sin(delta) + (Vd/Xq)*cos(delta) + (dVq_dd/Xd)*cos(delta) + ((Vfd-Vq)/Xd)*sin(delta);
    
    % omega に関する微分
    JI(1,2) = 0;
    JI(2,2) = 0;
    
    % Vre に関する微分
    JI(1,3) = (dVd_dre/Xq)*cos(delta) - (dVq_dre/Xd)*sin(delta);
    JI(2,3) = (dVd_dre/Xq)*sin(delta) + (dVq_dre/Xd)*cos(delta);
    
    % Vim に関する微分
    JI(1,4) = (dVd_dim/Xq)*cos(delta) - (dVq_dim/Xd)*sin(delta);
    JI(2,4) = (dVd_dim/Xq)*sin(delta) + (dVq_dim/Xd)*cos(delta);
end