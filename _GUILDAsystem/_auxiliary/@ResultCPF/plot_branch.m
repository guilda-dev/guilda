function G = plot_branch(obj, opt)
% Plot the branch flows along the path.
%
% The flows of each step come from the bus voltages cm_Vbus and the admittance matrix
% cm_Y of each branch in the snapshot sct_network: [I_from; I_to] = cm_Y [V_from; V_to],
% S = V conj(I) at each end. Drawn against lambda by Quantity:
%
% - "P": P_from, the active power into the branch at its first bus [pu].
% - "S": the larger apparent power |S| of the two ends [pu].
% - "loading": that apparent power over Smax of the branch (operating limits in the
%   snapshot), with a dotted line at 1; a branch with an infinite or NaN Smax has no line.
% - "loss": the active power loss P_from + P_to [pu]: with no Branch given, one line
%   "total", the loss of the whole network (the sum over the branches); with Branch, one
%   line per branch.
%
% Branch selects the branches (tags of the branches of sct_network, or "all"); with no
% Branch every branch is drawn (for "loss": the total). A dashed line marks the nose. The
% samples of the chart are the steps (rv_t = 1 ... n_step, named "Step"): G.set_time(k)
% puts a marker on each line at step k, and G.link(G2) keeps it in step with
% plot_pvcurve, plot_diagram and the other plots of the steps. A result without the
% snapshot stops with GUILDA:ResultCPF:NoStepData; "loading" with no finite Smax stops
% with GUILDA:ResultCPF:NoLimit.
%
% It returns the chart G (GraphChart): one line per branch, tagged with the branch tag
% (or "total").
%
% <@Examples>
% ```matlab
% res = net.calculate_continuation_powerflow(LoadBus=["B009","B014"]);
% G = res.plot_branch(Quantity="S");
% res.plot_branch(Quantity="loss");                       % total loss
% res.plot_branch(Quantity="P", Branch=["B004_B009", "B007_B009"]);
% ```
%
% See also ResultPF.plot_branch, ResultCPF.plot_diagram, ResultCPF.plot_pvcurve
    arguments (Input)
        obj
        opt.Quantity (1,1) string {mustBeMember(opt.Quantity, ["P","S","loading","loss"])} = "P"  % Value of the lines (see the list).
        opt.Branch {mustBeText} = ""  % Tags of the branches to draw, or "all"; "" (default) every branch, or the total loss for "loss".
        opt.Parent = []  % Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure.
    end
    arguments (Output)
        G  % The chart (GraphChart), one line per branch.
    end
    check_step_data(obj, "plot_branch", ["cm_Vbus", "sct_network"]);

    a_br  = reshape(obj.sct_network.a_Branch, [], 1);
    n_br  = numel(a_br);
    sv_br = strings(n_br, 1);
    sv_net = string(cellfun(@(b) b.s_tag, reshape(obj.sct_network.a_Bus, [], 1), "UniformOutput", false));
    n_step = numel(obj.rv_lambda);
    cm_Sfrom = complex(zeros(n_br, n_step));
    cm_Sto   = complex(zeros(n_br, n_step));
    rv_Smax  = inf(n_br, 1);
    for k = 1:n_br
        br = a_br{k};
        sv_br(k) = string(br.s_tag);
        iv_end = zeros(1, 2);
        sv_ref = string(br.a_Bus(:));                % "net.a_Bus{i}" (snapshot) or bus tags
        for m = 1:2
            s_num = regexp(sv_ref(m), "a_Bus\{(\d+)\}", "tokens", "once");
            if isempty(s_num)
                s_tag = sv_ref(m);
            else
                s_tag = sv_net(str2double(s_num));
            end
            iv_end(m) = find(obj.sv_bus == s_tag, 1);
        end
        cm_V = obj.cm_Vbus(iv_end, :);               % 2 x steps
        cm_S = cm_V .* conj(br.cm_Y * cm_V);
        cm_Sfrom(k, :) = cm_S(1, :);
        cm_Sto(k, :)   = cm_S(2, :);
        tab = br.tab_parameter;
        if ismember("operation", tab.Properties.VariableNames) && ismember("Smax", tab.operation.Properties.VariableNames)
            rv_Smax(k) = tab.operation.Smax;
        end
    end

    sv_plot = string(opt.Branch);
    l_total = opt.Quantity == "loss" && isequal(sv_plot, "");
    if isequal(sv_plot, "") || isequal(sv_plot, "all")
        sv_plot = sv_br;
    end
    [lv_found, iv_sel] = ismember(sv_plot(:), sv_br);
    if ~all(lv_found)
        error(msg("GUILDA:ResultCPF:UnknownBranch", join(sv_plot(~lv_found), ", ")));
    end

    rm_Smag = max(abs(cm_Sfrom), abs(cm_Sto));
    sct = step_sample(obj);
    sct.sct_refline = struct("s_axis", {}, "r_value", {}, "s_label", {}, "rv_color", {}, "s_lineStyle", {});
    sv_tag = sv_br(iv_sel);
    switch opt.Quantity
        case "P"
            rm_y = real(cm_Sfrom(iv_sel, :)).';
            s_ylabel = "P_{from} [pu]";
        case "S"
            rm_y = rm_Smag(iv_sel, :).';
            s_ylabel = "max |S| [pu]";
        case "loading"
            lv_keep = isfinite(rv_Smax(iv_sel));
            if ~any(lv_keep)
                error(msg("GUILDA:ResultCPF:NoLimit", "branch", "Smax", opt.Quantity));
            end
            iv_sel = iv_sel(lv_keep);
            sv_tag = sv_br(iv_sel);
            rm_y = (rm_Smag(iv_sel, :) ./ rv_Smax(iv_sel)).';
            s_ylabel = "|S| / S_{max}";
            sct.sct_refline(end+1) = struct("s_axis", "y", "r_value", 1, "s_label", "S_{max}", ...
                "rv_color", [0.85 0.33 0.10], "s_lineStyle", ":");
        case "loss"
            rm_loss = real(cm_Sfrom + cm_Sto);
            if l_total
                rm_y = sum(rm_loss, 1).';
                sv_tag = "total";
            else
                rm_y = rm_loss(iv_sel, :).';
            end
            s_ylabel = "P_{loss} [pu]";
    end
    if ~isnan(obj.r_lambdaMax)
        sct.sct_refline(end+1) = struct("s_axis", "x", "r_value", obj.r_lambdaMax, ...
            "s_label", "\lambda_{max}", "rv_color", [0.15 0.15 0.15], "s_lineStyle", "--");
    end
    sct.sct_panel = struct("s_title", "Branch flows (" + opt.Quantity + ")", "s_xlabel", "\lambda", ...
        "s_ylabel", s_ylabel, "l_time", true, "s_cursor", "marker", "s_legendLocation", "best");
    sct.sct_series = struct("rv_x", reshape(obj.rv_lambda, 1, []), "rm_y", rm_y, ...
        "sv_tag", sv_tag, "r_lineWidth", 1.2);
    G = GraphChart(sct, Parent=opt.Parent);
end
