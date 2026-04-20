function [dx, I, y] = dynamics(x, V, u, tab_parameter)
    Xd   = tab_parameter{1, 'Xd'};
    Xd_p = tab_parameter{1, 'Xd_p'};
    Xq   = tab_parameter{1, 'Xq'};
    D    = tab_parameter{1, 'D'};
    
    omega0 = GUILDAconfig.omega0;

    delta = x(1);
    omega = x(2);
    eq    = x(3);

    tm0    = u(1);
    vf0   = u(2);

    Vh = V;

    vd = abs(Vh)*sin(delta-angle(Vh));
    vq = abs(Vh)*cos(delta-angle(Vh));
    id = (eq-vq)/Xd_p;
    iq = vd/Xq;
    te = vq*iq+vd*id;                    

    dx = [      diff(delta, 1) == omega0*omega;
              M*diff(omega, 1) == tm0-te-D*omega;
          Td0_p*diff(eq   , 1) == -eq-(Xd-Xd_p)*id+vf0];
    
    I = exp(1j*delta)*(iq-1j*id);        

    y = [];
end

% dq変換
% Vdq = exp(1j*delta) * conj(V);
% Vd  = imag(Vdq);
% Vq  = real(Vdq);

% 出力方程式
% Id  = 1/Xdp * (Eq-Vq); 
% Iq  = 1/Xq  * (Vd);
% Idq = Iq + 1j*Id;
% I   = exp(1j*delta) * conj(Idq);

% 中間変数の作成
% Pout =  Vd*Id + Vq*Iq;

% 微分方程式
% ddelta = omega0 *omega;
% domega = - D*omega - Pout + Pm;
% dE     = - Eq - (Xd-Xdp)*Id + Vfd;
% dx = [ddelta; domega; dE];