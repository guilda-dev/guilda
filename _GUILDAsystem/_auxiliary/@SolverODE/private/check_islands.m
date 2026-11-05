function check_islands(net, c_open, tab_phase)
% Each set of open branches must leave every bus connected to a component: nothing sets
% the voltages of a part of the network without components (with no shunt either, the
% DAE is singular). Checked for all phases before the integration starts.
    sv_bus = string(net.a_Bus);
    sv_br  = string(net.a_Branch);
    iv_bus = zeros(numel(sv_br), 2);
    for k = 1:numel(sv_br)
        [~, iv_bus(k,:)] = ismember(string(net.a_Branch{k}.a_Bus), sv_bus);
    end
    lv_comp = cellfun(@(b) ~isempty(b.a_Component), net.a_Bus);
    for tp = 1:numel(c_open)
        if isempty(c_open{tp})
            continue
        end
        lv_on   = ~ismember(sv_br, c_open{tp});
        G       = graph(iv_bus(lv_on,1), iv_bus(lv_on,2), [], numel(sv_bus));
        iv_part = conncomp(G);
        lv_dead = ~ismember(iv_part, iv_part(lv_comp(:).'));
        if any(lv_dead)
            error(msg("GUILDA:SolverODE:OpenBranchIsland", num2str(tp), num2str(tab_phase{tp,"t1"}), ...
                      num2str(tab_phase{tp,"t2"}), char(join(c_open{tp}, ", ")), char(join(sv_bus(lv_dead), ", "))));
        end
    end
end
