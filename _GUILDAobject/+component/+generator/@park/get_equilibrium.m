function [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj,c_V,c_I,r_P,r_Q)
% Calculate the equilibrium state and the steady inputs from the power flow.
%
% Called by `set_equilibrium` with the power-flow solution. The rotor angle comes
% from the terminal voltage and the injected power; the speed deviation is 0.
%
% See also fcn_dx, Component.rv_Xequilibrium
    arguments
        obj 
        c_V % [pu] Complex bus voltage of the power-flow solution.
        c_I % [pu] Complex current injected into the bus.
        r_P = real( c_V*conj(c_I) ); % [pu] Active power injected into the bus.
        r_Q = imag( c_V*conj(c_I) ); % [pu] Reactive power injected into the bus.
    end
    arguments (Output)
        rv_Xequilibrium % Equilibrium state in the order of `sv_x`.
        rv_Uequilibrium % Steady input in the order of `sv_u`.
    end

    % 定常潮流状態の計算
    Vabs = abs(c_V);
    Varg = angle(c_V);
    
    % パラメータ値の抽出
    para = obj.para_dynamics;
    Xd   = para.Xd;
    Xq   = para.Xq;
    Xdp  = para.Xd_p;
    Xqp  = para.Xq_p;
    Xdpp = para.Xd_pp;
    Xqpp = para.Xq_pp;
    Xls  = para.X_ls;


    % 動揺方程式に対応するサブシステムの平衡点計算
    dst = Varg + atan(r_P/(r_Q+Vabs^2/Xq));    
    ost = 0;

    % 電磁気サブシステムの平衡点計算
    Idq = exp(1j*dst) * conj(c_I);
    Iq  = real(Idq);
    Id  = imag(Idq);

    dXd  = 1/(Xd-Xdp);
    dXq  = 1/(Xq-Xqp);
    dXdp = (Xdp-Xdpp)/(Xdp-Xls)^2;
    dXqp = (Xqp-Xqpp)/(Xqp-Xls)^2;
    SE   = [dXd+dXdp,    0    ,   0 , -dXdp;...
               0    , dXq+dXqp, dXqp,     0;...
               0    ,   dXqp  , dXqp,     0;...
             -dXdp  ,    0    ,   0 ,  dXdp];

    Vfd  = Xd/Vabs * ( (r_Q+Vabs^2/Xq)*(r_Q+Vabs^2/Xd) + r_P^2 ) / sqrt( (r_Q+Vabs^2/Xq)^2 + r_P^2 );
    wst = [Xdpp-Xls,        0;...
                  0, Xqpp-Xls;...
                  0,-Xqp+Xqpp;...
           Xdp-Xdpp,        0] * diag(1./[Xdp-Xls,Xqp-Xls]) * [-Id;Iq];
    ust = [dXd*Vfd; 0; 0; 0];

    Est = SE\(wst+ust);
    rv_Xequilibrium = [dst; ost; Est];
    rv_Uequilibrium = [r_P  ; Vfd];
end