function ax = plot_branch(obj, opt)
% Plot the branch flows of the power flow result.
%
% Draws one bar per branch (tab_branch order, tags on the axis). The bar height by Quantity:
%
% - "P": Pfrom, the active power into the branch at its first bus [pu].
% - "Q": Qfrom, the reactive power into the branch at its first bus [pu].
% - "S": the larger apparent power of the two ends [pu].
% - "loading": that apparent power over Smax of the branch (operating limits in the
%   snapshot; no bar when Smax is infinite), with a dashed line at 1 (Tag "Limit").
% - "loss": Ploss, the active power loss of the branch [pu].
%
% It reads only the stored result.
%
% <@Examples>
% ```matlab
% res = network.IEEE14bus().calculate_powerflow();
% res.plot_branch();                       % Pfrom of each branch
% res.plot_branch(Quantity="loading");     % |S| / Smax with the line at 1
% ```
%
% See also ResultPF.disp_branch, ResultPF.tab_branch, ResultPF.plot_voltage
    arguments (Input)
        obj
        opt.Parent = [] % Container to draw in. A new figure when empty.
        opt.Quantity (1,1) string {mustBeMember(opt.Quantity, ["P","Q","S","loading","loss"])} = "P" % Value of the bars (see the table).
    end
    arguments (Output)
        ax % Axes of the bar chart.
    end
    if isempty(opt.Parent)
        opt.Parent = figure();
    end
    tab   = obj.tab_branch;
    sv_br = string(tab.Properties.RowNames);
    rv_S  = max(abs([tab.Pfrom + 1j*tab.Qfrom, tab.Pto + 1j*tab.Qto]), [], 2);
    switch opt.Quantity
        case "P";       rv = tab.Pfrom;  s_label = "P_{from} [pu]";
        case "Q";       rv = tab.Qfrom;  s_label = "Q_{from} [pu]";
        case "S";       rv = rv_S;       s_label = "max |S| [pu]";
        case "loading"
            rv_Smax = branch_smax(obj);
            rv = rv_S ./ rv_Smax;
            rv(isinf(rv_Smax)) = NaN;     % no limit: no bar
            s_label = "|S| / S_{max}";
        case "loss";    rv = tab.Ploss;  s_label = "P_{loss} [pu]";
    end

    ax = axes(opt.Parent);
    bar(ax, categorical(sv_br, sv_br), rv, "Tag", "Branch");
    ylabel(ax, s_label);
    grid(ax, "on");
    title(ax, "Branch flows (" + opt.Quantity + ")");
    if opt.Quantity == "loading"
        yline(ax, 1, "--", "S_{max}", "Color", [0.85 0.33 0.10], "Tag", "Limit");
    end
end


function rv = branch_smax(obj)
% Smax of each branch from the snapshot (Inf without it)
    n  = height(obj.tab_branch);
    rv = inf(n,1);
    if isfield(obj.sct_network, "a_Branch") && numel(obj.sct_network.a_Branch) == n
        for k = 1:n
            rv(k) = obj.sct_network.a_Branch{k}.tab_parameter.operation.Smax;
        end
    end
end
