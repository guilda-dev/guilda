function [dx, I, y] = dynamics(x, V, u, tab_parameter)
    % パラメータ値の抽出
    Xd    = tab_parameter{1, 'Xd'   };
    Xq    = tab_parameter{1, 'Xq'   };
    Xd_p  = tab_parameter{1, 'Xd_p' };
    Xq_p  = tab_parameter{1, 'Xq_p' };
    Xd_pp = tab_parameter{1, 'Xd_pp'};
    Xq_pp = tab_parameter{1, 'Xq_pp'};
    Xl    = tab_parameter{1, 'X_ls' };
    D     = tab_parameter{1, 'D'    };
    
    omega0 = GUILDAconfig.omega0;


    % 状態変数の抽出
    delta = x(1);
    omega = x(2);
    eq    = x(3);
    ed    = x(4);
    psiq  = x(5);
    psid  = x(6);

    % 入力変数の抽出
    tm0  = u(1);
    vf0  = u(2);

    Vh = V;
    
    gamma_d1 = (Xd_pp-Xl)/(Xd_p-Xl);
    gamma_q1 = (Xq_pp-Xl)/(Xq_p-Xl);
    gamma_d2 = (Xd_p-Xd_pp)/(Xd_p-Xl)^2;
    gamma_q2 = (Xq_p-Xq_pp)/(Xq_p-Xl)^2;

    vd = abs(Vh)*sin(delta-angle(Vh));
    vq = abs(Vh)*cos(delta-angle(Vh));
    
    id = -vq/Xd_pp+(gamma_d1*eq+(1-gamma_d1)*psid)/Xd_pp;
    iq =  vd/Xq_pp-(gamma_q1*ed-(1-gamma_q1)*psiq)/Xq_pp;
    
    te = vq*iq+vd*id;        

    % 微分方程式
    dx = [                                     diff(delta, 1) ==   omega0*(omega-1);
                                             M*diff(omega, 1) == tm0-te-D*(omega-1);
          Td0_p*diff(eq, 1)+(Xd-Xd_p)*gamma_d2*diff( psid, 1) ==      -eq-(Xd-Xd_p)*id+vf0;
          Tq0_p*diff(ed, 1)-(Xq-Xq_p)*gamma_q2*diff( psiq, 1) ==      -ed+(Xq-Xq_p)*iq;
                                        Td0_pp*diff( psid, 1) == -psid+eq-(Xd_p-Xl)*id;
                                        Tq0_pp*diff( psiq, 1) == -psiq-ed-(Xq_p-Xl)*iq];

    I = exp(1j*delta)*(iq-1j*id);
    y = [];
end

% dq変換
% Vdq = exp(1j*delta) * conj(V);
% Vd  = imag(Vdq);
% Vq  = real(Vdq);

% 出力方程式
% terminal_q = ( (Xdpp-Xls)*Eq + (Xdp-Xdpp)*psid )/(Xdp-Xls);
% Id  = 1/Xdpp * (terminal_q-Vq); 
% 
% terminal_d = ( (Xqpp-Xls)*Ed - (Xqp-Xqpp)*psiq )/(Xqp-Xls);
% Iq  = 1/Xqpp * (Vd-terminal_d);
% 
% Idq = Iq + 1j*Id;
% I   = exp(1j*delta) * conj(Idq);

% 中間変数の作成
% Pout =  Vd*Id + Vq*Iq;
% ddelta = omega0 *omega;
% domega = - D*omega - Pout + Pm;
% dpsiq  = -psiq -Ed -(Xqp-Xls)*Iq;
% dpsid  = -psid +Eq -(Xdp-Xls)*Id;
% dEq    = - Eq - (Xd-Xdp)*( Id + (Xdp-Xdpp)/(Xdp-Xls)^2 * dpsid) + Vfd;
% dEd    = - Ed + (Xq-Xqp)*( Iq + (Xqp-Xqpp)/(Xqp-Xls)^2 * dpsiq);
% dx = [ddelta; domega; dEq; dEd; dpsiq; dpsid];



