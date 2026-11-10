function err = jacobian_error(obj)
% 解析的なヤコビアン (f_JacobiDx / f_JacobiI / f_JacobiY) と数値微分の最大誤差
%
%   err = DebugScript.helper.jacobian_error(comp)
%
% obj は Component / LocalController / GlobalController (平衡点を設定済みのもの)。
% SolverODE と同じ呼び出し方 f_Jacobi*(t,x,V,u) (機器の f_JacobiY は (t,x,V)) で得た行列を、
% f_dx / f_I / f_Y (Component) または f_dx / f_Y (制御器) の中心差分と比べる。
% 平衡点でだけ 0 になる項も確かめるため、平衡点から少しずらした点で比べる。
    arguments (Input)
        obj
    end
    arguments (Output)
        err  % 解析的なヤコビアンと数値微分の最大誤差
    end
    if isa(obj, "Component")
        V = [real(obj.c_Vequilibrium); imag(obj.c_Vequilibrium)];
        fcn = {@(x,V,u) obj.f_dx(0,x,V,u), @(x,V,u) cvec(obj.f_I(0,x,V,u)), @(x,V) obj.f_Y(0,x,V)};
        jac = {obj.f_JacobiDx, obj.f_JacobiI, obj.f_JacobiY};
        nv_arg = [3, 3, 2];    % 機器の出力は u を取らない
    else
        V = [1; 0];
        if isa(obj, "LocalController") && ~isempty(obj.c_Vequilibrium)   % PSS は電圧を保持しない
            V = [real(obj.c_Vequilibrium); imag(obj.c_Vequilibrium)];
        end
        fcn = {@(x,V,u) obj.f_dx(0,x,V,u), @(x,V,u) obj.f_Y(0,x,V,u)};
        jac = {obj.f_JacobiDx, obj.f_JacobiY};
        nv_arg = [3, 3];
    end
    x = obj.rv_Xequilibrium + 0.01*(1:numel(obj.rv_Xequilibrium))';
    u = obj.rv_Uequilibrium + 0.01*(1:numel(obj.rv_Uequilibrium))';
    V = 1.01*V;

    h   = 1e-6;
    err = 0;
    for f = 1:numel(fcn)
        arg = {x, V, u};
        arg = arg(1:nv_arg(f));
        J = cell(1,nv_arg(f));
        [J{:}] = jac{f}(0, arg{:});
        m = numel(fcn{f}(arg{:}));
        for a = 1:nv_arg(f)
            n  = numel(arg{a});
            Jn = zeros(m, n);
            for i = 1:n
                ap = arg;  ap{a}(i) = ap{a}(i) + h;
                am = arg;  am{a}(i) = am{a}(i) - h;
                Jn(:,i) = (fcn{f}(ap{:}) - fcn{f}(am{:})) / (2*h);
            end
            Ja = J{a};
            if isempty(Ja)
                Ja = zeros(m, n);
            end
            assert(isequal(size(Ja), [m, n]), "size of Jacobian %d/%d is %s, expected %s", f, a, mat2str(size(Ja)), mat2str([m, n]))
            err = max([err; abs(Ja(:) - Jn(:))]);
        end
    end
end

function v = cvec(c)
    arguments (Input)
        c  % 行列の cell 配列
    end
    arguments (Output)
        v  % 全要素を並べた列ベクトル
    end
    if isreal(c) && numel(c) == 2
        v = c(:);
    else
        v = [real(c); imag(c)];
    end
end
