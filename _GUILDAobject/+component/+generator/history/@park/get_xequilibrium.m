function xst = get_xequilibrium(obj,c_V,c_I)

    % 定常潮流状態の計算
    PQ   = c_V * conj(c_I);
    P    = real(PQ);
    Q    = imag(PQ);
    Vabs = abs(c_V);
    Varg = angle(c_V);
    
    % パラメータ値の抽出
    para = obj.tab_parameter.model;
    Xd   = para.Xd;
    Xq   = para.Xq;
    Xdp  = para.Xd_p;
    Xqp  = para.Xq_p;
    Xdpp = para.Xd_pp;
    Xqpp = para.Xq_pp;
    Xls  = para.X_ls;


    % 動揺方程式に対応するサブシステムの平衡点計算
    dst = Varg + atan(P/(Q+Vabs^2/Xq));
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

    Vfd  = Xd/Vabs * ( (Q+Vabs^2/Xq)*(Q+Vabs^2/Xd) + P^2 ) / sqrt( (Q+Vabs^2/Xq)^2 + P^2 );
    wst = [Xdpp-Xls,        0;...
                  0, Xqpp-Xls;...
                  0,-Xqp+Xqpp;...
           Xdp-Xdpp,        0] * diag(1./[Xdp-Xls,Xqp-Xls]) * [-Id;Iq];
    ust = [dXd*Vfd; 0; 0; 0];

    Est = SE\(wst+ust);
    xst = [dst; ost; Est];
end


