function e = finite_eigs(sys)
% 記述子形式モデル (E dx = A x) の有限な一般化固有値
%
%   e = DebugScript.helper.finite_eigs(sys)
%
% E が特異なとき (代数変数を含むとき) に出る無限大の固有値を除き、実部の順に並べる。
    arguments (Input)
        sys  % 記述子形式の状態空間モデル
    end
    arguments (Output)
        e  % 有限な一般化固有値 (実部の順)
    end
    e = eig(full(sys.A), full(sys.E));
    e = e(isfinite(e) & abs(e) < 1e6);
    e = sort(e, "ComparisonMethod", "real");
end
