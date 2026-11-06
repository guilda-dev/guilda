function check_edit(obj)
% Stop when a layer of the subtree is not up to date.
%
% Collects the messages of every stale tag of this layer and the layers below it
% (collect_stale) and stops with GUILDA:LayerPackage:Stale, naming up to
% three of them, when there are any: run net.initialize(). It changes nothing. Called on
% the network at the start of simulate, linearize, get_sys (SolverODE, SolverLIN), the
% continuation power flow (SolverCPF), the get_sys of each layer and
% LocalController.validate.
    arguments (Input)
        obj
    end
    sv = obj.collect_stale();
    if isempty(sv)
        return
    end
    sv = unique(sv, "stable");
    s_reason = join(sv(1:min(end,3)), "; ");
    if numel(sv) > 3
        s_reason = s_reason + "; ...";
    end
    error(msg("GUILDA:LayerPackage:Stale", char(obj.s_tag), char(s_reason)))
end

