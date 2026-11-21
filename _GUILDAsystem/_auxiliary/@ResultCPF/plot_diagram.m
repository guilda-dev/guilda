function G = plot_diagram(obj, opt)
% Draw the continuation power flow path as a network diagram (GraphNetDiagram) with every step.
%
% The diagram holds every step of the path as a sample (rv_t = 1 ... n_step, named
% "Step"; lambda is not monotonic past the nose): G.set_time(k) shows step k (the first
% one, the equilibrium, is shown at first), and the title and the control panel show
% "Step k (λ = ...)". G.animate() plays the steps, one frame per step. The bus voltages
% come from cm_Vbus, the current of each component from cm_Icomponent, and the branch
% flows from these voltages and the admittance matrices of the branches in the snapshot
% sct_network, so the colors, labels and arrows show the operating point of each step.
% G.link(G2) keeps it in step with plot_pvcurve, plot_spring_model and the other plots of
% the steps. It reads only the stored result. A result without the data of the steps
% (e.g. a ResultCPF built by hand) stops with GUILDA:ResultCPF:NoStepData. The other
% Name-Value options set the properties of the GraphNetDiagram.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% res = net.calculate_continuation_powerflow(LoadBus=["B009","B014"]);
% G  = res.plot_diagram(ColorMode="P", LabelMode="value");
% Gv = res.plot_pvcurve();
% G.link(Gv);
% G.set_time(res.r_noseStep);       % both at the nose
% ```
%
% See also ResultODE.plot_diagram, ResultPF.plot_diagram, GraphNetDiagram, ResultCPF.plot_spring_model
    arguments (Input)
        obj
        opt.?GraphNetDiagram  % Name-Value options; each sets the property of the same name of the GraphNetDiagram.
        opt.Parent = []       % Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure.
    end
    arguments (Output)
        G  % GraphNetDiagram object of the drawing.
    end
    check_step_data(obj, "plot_diagram", ["cm_Vbus", "cm_Icomponent", "sct_network"]);

    sct_state = step_sample(obj);
    sv_net = string(cellfun(@(b) b.s_tag, reshape(obj.sct_network.a_Bus, [], 1), "UniformOutput", false));
    [~, iv_row] = ismember(sv_net, obj.sv_bus);
    sct_state.cm_Vbus  = obj.cm_Vbus(iv_row, :);
    sct_state.cm_Icomp = obj.cm_Icomponent;

    c_opt = namedargs2cell(opt);
    G = GraphNetDiagram(obj.sct_network, sct_state, c_opt{:});
end
