function sys = dae2ode(sys)
% 微分方程式
% Exx dx = Axx X + Axv V + Bxu U;
%      y = Cyx X + Cyv V + D   U;
%
% 代数方程式
%    0 =  Avx X + Avv V + Bvu U
% ←→ V = -Avv^{-1} (Avx X + Bvu U)
%
% 代入
% Exx dx =  Axx X + Axv ( -Avv^{-1} (Avx X + Bvu U) ) + Bxu U    = (Axx - Axv/Avv*Avx) X + (Bxu - Axv/Avv*Bvu) U
%      y =  Cyx X + Cyv ( -Avv^{-1} (Avx X + Bvu U) ) + D   U    = (Cyx - Cyv/Avv*Avx) X + ( D  - Cyv/Avv*Bvu) U

    A = sys.A;
    B = sys.B;
    C = sys.C;
    D = sys.D;
    E = sys.E;

    iv_alg = reshape( all( E==0,1 ), [], 1);
    ih_alg = reshape( all( E==0,2 ), [], 1);
    i_alg  = iv_alg & ih_alg;

    Axx  = A(~i_alg,~i_alg);
    Axv  = A(~i_alg, i_alg);
    Avx  = A( i_alg,~i_alg);
    Avv  = A( i_alg, i_alg);

    Bxu  = B(~i_alg, :);
    Bvu  = B( i_alg, :);

    Cyx  = C(:,~i_alg);
    Cyv  = C(:, i_alg);

    Eode = E(~i_alg,~i_alg);

    Hvx  = Avv\Avx;
    Hvu  = Avv\Bvu;

    Aode = Axx - Axv*Hvx;
    Bode = Bxu - Axv*Hvu;
    Code = Cyx - Cyv*Hvx;
    Dode = D   - Cyv*Hvu;

    sys = dss(Aode, Bode, Code, Dode, Eode, ...
                "StateName",  sys.StateName(~i_alg),...
                "InputName",  sys.InputName,...
                "OutputName", sys.OutputName,...
                "InputGroup", sys.InputGroup,...
                "OutputGroup",sys.OutputGroup );

end