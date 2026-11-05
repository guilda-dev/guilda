function tf = same_eigs(e1, e2, tol)
% 2 つの固有値の集合が許容誤差 tol 内で一致するか
%
%   tf = DebugScript.helper.same_eigs(e1, e2, 1e-6)
%
% 個数が同じで、e1 の各固有値に対して e2 に tol 以内の固有値があれば true。
    arguments (Input)
        e1   % 固有値の集合
        e2   % 固有値の集合
        tol  % 許容誤差
    end
    arguments (Output)
        tf  % 一致すれば true
    end
    tf = numel(e1) == numel(e2) && ...
         all(arrayfun(@(e) min(abs(e2 - e)), e1) < tol) && ...
         all(arrayfun(@(e) min(abs(e1 - e)), e2) < tol);
end
