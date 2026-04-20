function xst = get_xequilibrium(obj,c_V,c_I)

    % 定常潮流状態の計算
    PQ   = c_V * conj(c_I);
    P    = real(PQ);
    Q    = imag(PQ);
    Vabs = abs(c_V);
    Varg = angle(c_V);
    
    % パラメータ値の抽出
    Xq   = obj.parameter.model.Xq;

    % 動揺方程式に対応するサブシステムの平衡点計算
    dst = Varg + atan(P/(Q+Vabs^2/Xq));

    xst = [dst; 0];

end


