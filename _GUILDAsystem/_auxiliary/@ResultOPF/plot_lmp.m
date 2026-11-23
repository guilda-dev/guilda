function G = plot_lmp(obj, opt)
% Draw the locational marginal prices on the network diagram (GraphNetDiagram).
%
% Each bus is colored by its LMP (get_lmp, cost per pu), with a color bar (ColorbarLabel
% "LMP [cost/pu]") and the title "LMP of <network> (<Method>)"; the color limits
% are the lowest and the highest LMP. The branches with a binding limit (the branch
% constraints of disp_binding: Pmax, Qmax, Imax, Smax, VargMax) are selected, so they are
% drawn in SelectionColor. The state of the diagram is the solution: the bus voltages
% (Vphasor in "AC OPF"; |V| = 1 and the angle Varg in "DC OPF"; V = 1 in "ELD", which has
% no angles) and the component powers of tab_cub. The branches and links keep a neutral
% color. The labels are LabelMode "value": each bus label shows its tag, ∠V, |V| and the
% line "LMP [cost/pu]=<value>" (%.4g), and each component label its tag, P and Q; the data
% tip of a bus shows the same LMP line. Works for "ELD", "DC OPF" and "AC OPF"; it reads
% only the stored result. The other Name-Value options set the properties of the
% GraphNetDiagram (they override the color and label settings above, e.g. LabelMode="bus"
% for the bus tags only).
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.a_Branch{1}.tab_parameter.operation.Pmax = 1;
% res = net.calculate_optimal_powerflow(Method="DC OPF");
% G = res.plot_lmp();
% G.Selection                 % the branches with a binding limit
% G.BusLabel(1)               % the tag, ∠V, |V| and "LMP [cost/pu]=<the LMP>" of the first bus
% G = res.plot_lmp(LabelMode="bus");   % the bus tags only
% ```
%
% See also ResultOPF.get_lmp, ResultOPF.disp_binding, GraphNetDiagram
    arguments (Input)
        obj
        opt.?GraphNetDiagram  % Name-Value options; each sets the property of the same name of the GraphNetDiagram.
        opt.Parent = []       % Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure.
    end
    arguments (Output)
        G  % GraphNetDiagram object of the drawing.
    end
    s_method = string(obj.options.Method);
    tab_lmp  = obj.get_lmp();
    switch s_method
        case "AC OPF"
            cv_V = obj.tab_bus.Vphasor;
            cv_S = obj.tab_cub.P + 1j*obj.tab_cub.Q;
        case "DC OPF"
            cv_V = exp(1j*obj.tab_bus.Varg);
            cv_S = obj.tab_cub.P;
        otherwise
            cv_V = ones(height(obj.tab_bus), 1);
            cv_S = obj.tab_cub.P;
    end
    [sct_state, sv_bus, sv_comp] = diagram_state(obj, cv_V, cv_S);
    rv_lmp = tab_lmp{sv_bus, "LMP"};
    rr_lim = [min(rv_lmp), max(rv_lmp)];
    if rr_lim(2) - rr_lim(1) <= 1e-9*max(1, abs(rr_lim(2)))     % one price everywhere
        rr_lim = rr_lim + [-1, 1]*max(1e-6, 1e-3*abs(rr_lim(2)));
    end
    n_br = numel(obj.sct_network.a_Branch);
    c_opt = [{"ColorMode", "user", "BusColorData", rv_lmp, "ColorLimits", rr_lim, "ColorbarLabel", "LMP [cost/pu]", ...
              "BranchColorData", nan(n_br, 1), "LinkColorData", nan(numel(sv_comp), 1), "LabelMode", "value"}, namedargs2cell(opt)];
    G = GraphNetDiagram(obj.sct_network, sct_state, c_opt{:});
    title(G.ax, "LMP of " + obj.s_network + " (" + s_method + ")");

    % the binding branch limits: Object is the branch ("VargMax") or "<branch>_<bus>" (one end)
    sv_br  = reshape(string(cellfun(@(b) b.s_tag, obj.sct_network.a_Branch, "UniformOutput", false)), [], 1);
    sv_obj = binding_table(obj).Object;
    lv_bind = arrayfun(@(b) any(sv_obj == b | startsWith(sv_obj, b + "_")), sv_br);
    if any(lv_bind)
        G.select(sv_br(lv_bind));
    end
end
