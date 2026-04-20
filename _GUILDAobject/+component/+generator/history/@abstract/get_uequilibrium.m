function ust = get_uequilibrium(obj,c_V,c_I)

    % 定常潮流状態の計算
    PQ   = c_V * conj(c_I);
    P    = real(PQ);
    Q    = imag(PQ);
    Vabs = abs(c_V);
    
    % パラメータ値の抽出
    para = obj.parameter.model;
    Xd   = para.Xd;
    Xq   = para.Xq;

    Pm  = P;
    Vfd = Xd/Vabs * ( (Q+Vabs^2/Xq)*(Q+Vabs^2/Xd) + P^2 ) / sqrt( (Q+Vabs^2/Xq)^2 + P^2 );

    ust = [Pm;Vfd];
end

