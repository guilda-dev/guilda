function G = plot_branch(obj, opt)
% Plot the branch flows of the power flow result.
%
% Draws one bar per branch (tab_branch order, tags on the axis). The bar height by Quantity:
%
% - "P": Pfrom, the active power into the branch at its first bus [pu].
% - "Q": Qfrom, the reactive power into the branch at its first bus [pu].
% - "S": the larger apparent power of the two ends [pu].
% - "loading": that apparent power over Smax of the branch (operating limits in the
%   snapshot; no bar when Smax is infinite), with a dashed reference line at 1.
% - "loss": Ploss, the active power loss of the branch [pu].
%
% It reads only the stored result. It returns the chart G (GraphChart) with one element
% per bar (kind "bar"), tagged with the branch tag.
%
% <@Examples>
% ```matlab
% res = network.IEEE14bus().calculate_powerflow();
% G = res.plot_branch();                   % Pfrom of each branch
% G.set_style(G.tab_element.Tag(1), Color="r");
% res.plot_branch(Quantity="loading");     % |S| / Smax with the line at 1
% ```
%
% See also GraphChart, ResultPF.disp_branch, ResultPF.tab_branch, ResultPF.plot_voltage
    arguments (Input)
        obj
        opt.Parent = []  % Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure.
        opt.Quantity (1,1) string {mustBeMember(opt.Quantity, ["P","Q","S","loading","loss"])} = "P"  % Value of the bars (see the table).
    end
    arguments (Output)
        G  % The chart (GraphChart), one bar per branch.
    end
    tab   = obj.tab_branch;
    sv_br = string(tab.Properties.RowNames);
    rv_S  = max(abs([tab.Pfrom + 1j*tab.Qfrom, tab.Pto + 1j*tab.Qto]), [], 2);
    sct   = struct();
    switch opt.Quantity
        case "P";       rv = tab.Pfrom;  s_label = "P_{from} [pu]";
        case "Q";       rv = tab.Qfrom;  s_label = "Q_{from} [pu]";
        case "S";       rv = rv_S;       s_label = "max |S| [pu]";
        case "loading"
            n = height(tab);
            rv_Smax = inf(n,1);     % Smax from the snapshot (Inf without it)
            if isfield(obj.sct_network, "a_Branch") && numel(obj.sct_network.a_Branch) == n
                for k = 1:n
                    rv_Smax(k) = obj.sct_network.a_Branch{k}.tab_parameter.operation.Smax;
                end
            end
            rv = rv_S ./ rv_Smax;
            rv(isinf(rv_Smax)) = NaN;     % no limit: no bar
            s_label = "|S| / S_{max}";
            sct.sct_refline = struct("r_value", 1, "s_label", "S_{max}");
        case "loss";    rv = tab.Ploss;  s_label = "P_{loss} [pu]";
    end
    sct.sct_panel  = struct("s_title", "Branch flows (" + opt.Quantity + ")", "s_ylabel", s_label);
    sct.sct_series = struct("s_type", "bar", "sv_x", sv_br, "rm_y", rv);
    G = GraphChart(sct, Parent=opt.Parent);
end
