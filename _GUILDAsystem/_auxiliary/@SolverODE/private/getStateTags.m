function [Btag_all, Ctag_all] = getStateTags(net)
% Tag of each entry of the state vector, from the network as it is now.
    a_bus  = net.a_Bus;
    sv_tag = cell(size(a_bus));
    rv_rep = cell(size(a_bus));

    for i = 1:numel(a_bus)
        [sv_tag{i}, rv_rep{i}] = getTM(a_bus{i}.a_Component);
    end

    % global controllers follow the components in the state vector (see initialize_index)
    a_GCs = net.a_GlobalController;
    for k = 1:numel(a_GCs)
        sv_tag = [sv_tag; {a_GCs{k}.s_tag}]; %#ok
        rv_rep = [rv_rep; {numel(a_GCs{k}.sv_x)}]; %#ok
    end

    Btag_all = repelem(string(a_bus), 4*ones(numel(a_bus),1));
    Ctag_all = repelem(vertcat(sv_tag{:}), vertcat(rv_rep{:}));
end
