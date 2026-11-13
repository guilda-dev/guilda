function [sct_base, s_refBus] = opf_setting(net, s_ref)
% Base and reference bus of the optimal power flow of the network.
%
% Used by calculate_optimal_powerflow and build_opf_problem next to get_opf_condition:
% - sct_base: the base parameters of the network (baseMVA, Hz), p.base of Cost and
%   Constraint.
% - s_refBus: the ReferenceBus option s_ref, with "auto" resolved to the tag of the bus of
%   tools.slack_bus_index (else the first bus; "none" without buses); a tag or "none" is
%   returned as it is (unknown tags are checked by SolverOPF).
    arguments (Input)
        net                          % Network; only read.
        s_ref (1,1) string = "auto"  % ReferenceBus option.
    end
    arguments (Output)
        sct_base struct              % baseMVA, Hz of the network.
        s_refBus (1,1) string        % Tag of the reference bus, or "none".
    end
    sct_base = table2struct(net.a_Parameter{cellfun(@(p) p.s_tag=="base", net.a_Parameter)}.tab_parameter);
    s_refBus = s_ref;
    if s_ref ~= "auto"
        return
    end
    if isempty(net.a_Bus)
        s_refBus = "none";
        return
    end
    i_ref = tools.slack_bus_index(net);
    if isempty(i_ref)
        i_ref = 1;
    end
    s_refBus = string(net.a_Bus{i_ref});
end
