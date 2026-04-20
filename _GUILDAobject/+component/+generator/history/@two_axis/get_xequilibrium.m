function xst = get_xequilibrium(obj,c_V,c_I)

    % 定常潮流状態の計算
    PQ   = c_V * conj(c_I);
    P    = real(PQ);
    Q    = imag(PQ);
    Vabs = abs(c_V);
    Varg = angle(c_V);
    
    % パラメータ値の抽出
    para = obj.parameter.model;
    Xd   = para.Xd;
    Xq   = para.Xq;
    Xdp  = para.Xd_p;
    Xqp  = para.Xq_p;

    % 動揺方程式に対応するサブシステムの平衡点計算
    dst = Varg + atan(P/(Q+Vabs^2/Xq));
    wst = 0;

    % 電磁気サブシステムの平衡点計算
    Idq = exp(1j*dst) * conj(c_I);
    Iq  = real(Idq);
    Id  = imag(Idq);
    Vfd = Xd/Vabs * ( (Q+Vabs^2/Xq)*(Q+Vabs^2/Xd) + P^2 ) / sqrt( (Q+Vabs^2/Xq)^2 + P^2 );
    Est = [ -(Xd-Xdp)*Id + Vfd; ...
             (Xq-Xqp)*Iq      ];
    
    xst = [dst; wst; Est];
end
