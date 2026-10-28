function tab = pf_component_power(net, tab_bus)
% 潮流計算の解 (母線ごとの P, Q) を機器ごとの P, Q に分ける
%
%   tab = DebugScript.helper.pf_component_power(net, tab_PFsol)
%
% 負荷は潮流設定の P, Q のまま、残りを母線の負荷以外の機器 (1 母線に 1 台まで) に割り当てる。
% 行名は機器名で、DebugScript.helper.opf_cost にそのまま渡せる。
    str = string.empty(0,1);
    PQ  = zeros(0,2);
    for i = 1:numel(net.a_Bus)
        bus   = net.a_Bus{i};
        a_Com = bus.a_Component;
        if isempty(a_Com); continue; end
        l_load = cellfun(@(c) isa(c,"component.load.abstract"), a_Com);
        assert(sum(~l_load) <= 1, string(bus) + " に負荷以外の機器が複数ある")
        PQ_set = zeros(numel(a_Com),2);
        for k = 1:numel(a_Com)
            PQ_set(k,:) = a_Com{k}.tab_parameter.powerflow{1,["P","Q"]};
        end
        PQ_rest = real(tab_bus{string(bus),["P","Q"]}) - sum(PQ_set(l_load,:), 1);
        for k = 1:numel(a_Com)
            c = a_Com{k};
            if l_load(k)
                PQ_k = PQ_set(k,:);
            else
                PQ_k = PQ_rest;
            end
            str = [str; string(c)];   %#ok
            PQ  = [PQ; PQ_k];         %#ok
        end
    end
    tab = array2table(PQ, "VariableNames",["P","Q"], "RowNames",str);
end
