function tf = same_eigs(e1, e2, tol)
% 2 つの固有値の集合が許容誤差 tol 内で一致するか
%
%   tf = DebugScript.helper.same_eigs(e1, e2, 1e-6)
%
% 個数が同じで、e1 の各固有値に対して e2 に tol 以内の固有値があれば true。
    tf = numel(e1) == numel(e2) && ...
         all(arrayfun(@(e) min(abs(e2 - e)), e1) < tol) && ...
         all(arrayfun(@(e) min(abs(e1 - e)), e2) < tol);
end
