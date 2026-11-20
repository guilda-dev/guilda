function [r_dx, r_I] = equilibrium_residual(comp)
% 平衡点での機器の状態微分と注入電流の残差
%
%   [r_dx, r_I] = DebugScript.helper.equilibrium_residual(comp)
%
%   r_dx : max|f_dx(x*, V*, u*)|  (状態のない負荷は 0)
%   r_I  : |f_I(x*, V*, u*) - I*| (機器の出力電流と潮流計算の電流の差)
% 機器が保持している関数ハンドル f_dx, f_I をそのまま使う
% (シミュレーションで使われる式と同じ)。
    arguments (Input)
        comp  % 平衡点を設定済みの機器
    end
    arguments (Output)
        r_dx  % max|f_dx(x*, V*, u*)|
        r_I   % |f_I(x*, V*, u*) - I*|
    end
    V  = comp.c_Vequilibrium;
    I  = comp.c_Iequilibrium;
    rv_V = [real(V); imag(V)];
    dx = comp.f_dx(0, comp.rv_Xequilibrium, rv_V, comp.rv_Uequilibrium);
    Ic = comp.f_I( 0, comp.rv_Xequilibrium, rv_V, comp.rv_Uequilibrium);
    r_dx = max([abs(dx(:)); 0]);
    if isreal(Ic) && numel(Ic) == 2
        Ic = Ic(1) + 1j*Ic(2);
    end
    r_I = abs(Ic - I);
end
