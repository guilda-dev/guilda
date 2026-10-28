function J = opf_cost(net, tab)
% 機器ごとの P, Q を持つ表 tab (行名 = 機器名) で OPF の費用関数を評価する
%
%   J = DebugScript.helper.opf_cost(net, tab_cub)
%
% 費用は機器の tab_parameter.OPF の HP*P^2 + fP*P + HQ*Q^2 + fQ*Q の合計。
% tab に Q 列が無い場合 (ELD, DC OPF) は P の項だけを足す。
    a_Com = tools.vcellfun(@(b) b.a_Component, net.a_Bus);
    l_Q   = ismember("Q", tab.Properties.VariableNames);
    J = 0;
    for k = 1:numel(a_Com)
        c = a_Com{k};
        o = c.tab_parameter.OPF;
        P = real(tab{string(c),"P"});
        J = J + o.HP*P^2 + o.fP*P;
        if l_Q
            Q = real(tab{string(c),"Q"});
            J = J + o.HQ*Q^2 + o.fQ*Q;
        end
    end
end
