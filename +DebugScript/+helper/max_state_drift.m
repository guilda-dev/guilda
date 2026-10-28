function d = max_state_drift(sol)
% シミュレーション結果の全機器状態・全母線電圧の初期値からの最大変化量
%
%   d = DebugScript.helper.max_state_drift(sol)   % sol: odeSimulationResult
%
% 解列中の機器 (NaN) は無視する。外乱なしで平衡点に留まっていれば d ≈ 0。
    r = sol.odeResults;
    d = 0;
    for i = 1:numel(r.Bus)
        V = r.Bus(i).V.Variables;
        d = max(d, max(abs(V - V(1,:)), [], "all", "omitnan"));
        for j = 1:numel(r.Bus(i).Component)
            if ~isfield(r.Bus(i).Component(j),"X") || isempty(r.Bus(i).Component(j).X)
                continue
            end
            X = r.Bus(i).Component(j).X.Variables;
            if isempty(X); continue; end
            d = max(d, max(abs(X - X(1,:)), [], "all", "omitnan"));
        end
    end
end
