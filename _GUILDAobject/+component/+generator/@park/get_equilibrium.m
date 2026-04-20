function [cv_Xequilibrium, cv_Uequilibrium] = get_equilibrium(obj,c_V,c_I,r_P,r_Q)
    arguments
        obj 
        c_V
        c_I
        r_P = real( c_V*conj(c_I) );
        r_Q = imag( c_V*conj(c_I) ); 
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
    cv_Xequilibrium = [dst; ost; Est];
    cv_Uequilibrium = [r_P  ; Vfd];
end