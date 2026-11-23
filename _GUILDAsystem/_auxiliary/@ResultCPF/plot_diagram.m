function [G, G_pv] = plot_diagram(obj, opt)
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
% With PVCurve true (default), the container (Parent, or a new figure of 1400 x 600 px) is
% split: the diagram on the left (2/3 of the width) and plot_pvcurve(Bus=PVBus) on the
% right (1/3), linked with G.link(G_pv), so the playback of the diagram moves the markers on
% the PV curves. A uigridlayout Parent gets a borderless uipanel first. PVCurve false, or
% an axes or uiaxes Parent, draws the diagram alone as before (G_pv []). A PVBus tag that is
% not in sv_bus stops with GUILDA:ResultCPF:UnknownBus.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% res = net.calculate_continuation_powerflow(LoadBus=["B009","B014"]);
% [G, G_pv] = res.plot_diagram(ColorMode="P", LabelMode="value");   % PV curves on the right
% G.set_time(res.r_noseStep);       % both at the nose
% G2 = res.plot_diagram(PVCurve=false);   % the diagram alone
% ```
%
% See also ResultODE.plot_diagram, ResultPF.plot_diagram, GraphNetDiagram, ResultCPF.plot_spring_model
    arguments (Input)
        obj
        opt.?GraphNetDiagram  % Name-Value options; each sets the property of the same name of the GraphNetDiagram.
        opt.PVCurve (1,1) logical = true  % Draw the PV curves with the plot (see the help); false: the plot alone.
        opt.PVBus {mustBeText} = ""       % Buses of the PV curves: "" those of plot_pvcurve (options.LoadBus; every bus when none), "all" every bus, or bus tags.
        opt.Parent = []       % Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure.
    end
    arguments (Output)
        G     % GraphNetDiagram object of the drawing.
        G_pv  % The PV chart (GraphChart, plot_pvcurve) on the right, linked to G; [] with PVCurve false or an axes Parent.
    end
    check_step_data(obj, "plot_diagram", ["cm_Vbus", "cm_Icomponent", "sct_network"]);

    sct_state = step_sample(obj);
    sv_net = string(cellfun(@(b) b.s_tag, reshape(obj.sct_network.a_Bus, [], 1), "UniformOutput", false));
    [~, iv_row] = ismember(sv_net, obj.sv_bus);
    sct_state.cm_Vbus  = obj.cm_Vbus(iv_row, :);
    sct_state.cm_Icomp = obj.cm_Icomponent;

    c_opt = namedargs2cell(rmfield(opt, ["PVCurve", "PVBus", "Parent"]));
    [G, G_pv] = pair_pvcurve(obj, opt, @(h) GraphNetDiagram(obj.sct_network, sct_state, c_opt{:}, Parent=h));
end
