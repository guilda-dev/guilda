function simulateFcn_check(net, s_id)
% The checks before a time simulation: edited inputs, and the stale tags of the network
% and of its components and controllers (net.initialize() is needed).
%
% Stops with GUILDA:PowerNetwork:SimulateInputEdited when inputs of components were edited
% (initialize(Method="FixedInput")), and with GUILDA:PowerNetwork:SimulateStale naming up
% to three reasons otherwise. Another caller that needs the equilibrium (plot_spring_model, plot_diagram)
% gives its own error id s_id: then edited inputs are one more stale reason.
    arguments (Input)
        net  % Network of the run.
        s_id (1,1) string = "GUILDA:PowerNetwork:SimulateStale" % Error id of a stale network; its message takes the network tag and the reasons.
    end
    l_simulate = s_id == "GUILDA:PowerNetwork:SimulateStale";
    if l_simulate && ~isempty(net.sct_stale.input)   % edited inputs: initialize(Method="FixedInput")
        sv_in = unique(net.sct_stale.input, "stable");
        error(msg("GUILDA:PowerNetwork:SimulateInputEdited", char(net.s_tag), char(join(sv_in(1:min(end,3)), "; "))))
    end
    sv = [net.sct_stale.powerflow; net.sct_stale.odefcn];   % messages of the stale tags
    if ~l_simulate
        sv = [sv; net.sct_stale.input];
    end
    for i = 1:numel(net.a_Bus)
        a_comp = net.a_Bus{i}.a_Component;
        for j = 1:numel(a_comp)
            a_obj = [a_comp(j); all_controllers(a_comp{j})];
            for k = 1:numel(a_obj)
                sv = [sv; a_obj{k}.sct_stale.equilibrium; a_obj{k}.sct_stale.odefcn]; %#ok<AGROW>
            end
        end
    end
    a_gc = net.a_GlobalController;
    for k = 1:numel(a_gc)
        sv = [sv; a_gc{k}.sct_stale.equilibrium; a_gc{k}.sct_stale.odefcn]; %#ok<AGROW>
    end
    if ~isempty(sv)
        sv = unique(sv, "stable");
        s_reason = join(sv(1:min(end,3)), "; ");
        if numel(sv) > 3
            s_reason = s_reason + "; ...";
        end
        error(msg(s_id, char(net.s_tag), char(s_reason)))
    end
end
