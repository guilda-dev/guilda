function [dx, I, y] = dynamics(x, V, u, tab_parameter) %#ok
    Xd = tab_parameter{1,'Xd'};
    Xq = tab_parameter{1,'Xq'};
    D  = tab_parameter{1,'D'};

    omega0 = GUILDAconfig.omega0;
    
    delta = x(1);
    omega = x(2);

    tm0 = u(1);
    vf0 = u(2);

    vd = abs(Vh)*sin(delta-angle(Vh));
    vq = abs(Vh)*cos(delta-angle(Vh));     
    id = (eq-vq)/Xd;
    iq = vd/Xq;
    te = vq*iq+vd*id;
    
    dx = [  diff(delta, 1) == omega0*(omega-1);
          M*diff(omega, 1) == tm0-te-D*(omega-1)+vf0];
    
    I = exp(1j*delta)*(iq-1j*id);  

    y   = [];    
end

% dq変換
% Vdq = exp(1j*delta) * conj(V);
% Vd  = imag(Vdq);
% Vq  = real(Vdq);

% 出力方程式
% Id  = (Vfd-Vq)/Xd;
% Iq  = Vd/Xq;
% Idq = Iq + 1j*Id;
% I   = exp(1j*delta) * conj(Idq);

% 中間変数
% Pout = Vq*Iq + Vd*Id;

% 微分方程式
% ddelta = omega0 * omega;
% domega = - D*omega - Pout + Pm;
% dx  = [ddelta; domega];