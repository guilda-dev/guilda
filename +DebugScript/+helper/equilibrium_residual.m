function [r_dx, r_I] = equilibrium_residual(comp)
% 平衡点での機器の状態微分と注入電流の残差
%
%   [r_dx, r_I] = DebugScript.helper.equilibrium_residual(comp)
%
%   r_dx : max|f_dx(x*, V*, I*, u*)|  (状態のない負荷は 0)
%   r_I  : |f_I(x*, V*, I*, u*) - I*| (機器の出力電流と潮流計算の電流の差)
% 機器が保持している関数ハンドル f_dx, f_I をそのまま使う
% (シミュレーションで使われる式と同じ)。
    V  = comp.c_Vequilibrium;
    I  = comp.c_Iequilibrium;
    rv_V = [real(V); imag(V)];
    rv_I = [real(I); imag(I)];
    dx = comp.f_dx(0, comp.rv_Xequilibrium, rv_V, rv_I, comp.rv_Uequilibrium);
    Ic = comp.f_I( 0, comp.rv_Xequilibrium, rv_V, rv_I, comp.rv_Uequilibrium);
    r_dx = max([abs(dx(:)); 0]);
    if isreal(Ic) && numel(Ic) == 2
        Ic = Ic(1) + 1j*Ic(2);
    end
    r_I = abs(Ic - I);
end
