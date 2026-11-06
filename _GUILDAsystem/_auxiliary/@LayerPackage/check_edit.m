function check_edit(obj)
% Stop when a layer of the subtree is not up to date.
%
% Collects the messages of every stale tag (sct_stale) of this layer and the layers below
% it and stops with GUILDA:LayerPackage:Stale, naming up to three different ones, when
% there are any: run net.initialize(). It changes nothing. Called on the network at the
% start of simulate, linearize, get_sys (SolverODE, SolverLIN), the continuation power
% flow (SolverCPF), the get_sys of each layer and LocalController.validate.
    arguments (Input)
        obj
    end
    sv = subtree_stale(obj);
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


function sv = subtree_stale(obj)
% Messages of the stale tags of obj and its descendants. A Parameter container among the
% children has no stale tags and no children.
    c  = struct2cell(obj.sct_stale);
    sv = vertcat(strings(0,1), c{:});
    a_children = obj.children;
    for i = 1:numel(a_children)
        if ~isa(a_children{i}, "Parameter")
            sv = [sv; subtree_stale(a_children{i})]; %#ok<AGROW>
        end
    end
end
