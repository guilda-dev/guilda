function S = branch_losses(net, cv_V)
% 母線電圧 cv_V のときの全送電線の複素損失 (P損失 + jQ損失) の合計
%
%   S = DebugScript.helper.branch_losses(net, tab.Vphasor)
%
% 各送電線の 2x2 アドミタンス行列から両端の注入電力を計算して合計する。
% 母線のシャント (Gshunt, Bshunt) も含める。
    str_bus = string(net.a_Bus);
    S = 0;
    for k = 1:numel(net.a_Branch)
        br = net.a_Branch{k};
        [~, idx] = ismember(string(br.a_Bus), str_bus);
        Vb = cv_V(idx(:));
        Ib = br.get_admittance_matrix() * Vb;
        S  = S + sum(Vb .* conj(Ib));
    end
    for i = 1:numel(net.a_Bus)
        y = net.a_Bus{i}.tab_parameter.dynamics{1,["Gshunt","Bshunt"]} * [1;1j];
        S = S + abs(cv_V(i))^2 * conj(y);
    end
end
