function G = plot_spring_model(obj, opt)
% Draw the continuation power flow path as a spring-mass picture with every step.
%
% The picture holds every step of the path as a sample (rv_t = 1 ... n_step, named
% "Step"): G.set_time(k) shows step k, G.animate() plays the steps (one frame per step)
% and G.export_video(file) writes them as a video; the title shows "Step k (λ = ...)".
% The nodes, springs and arrows are those of ResultODE.plot_spring_model
% (tools.spring_model_data): every bus, and the own node of each component whose class
% returns one from its Static get_spring_node (e.g. the internal voltage of a generator),
% with the states x and inputs u of the components at each step (tab_variable,
% rm_variable), the bus voltages cm_Vbus and the component currents cm_Icomponent.
% Dimension=2 draws the phasor plane (GraphSpring2D), Dimension=3 the surface z = log|V|
% (GraphSpring3D). A component whose values are NaN at a step (its get_equilibrium
% stopped there) has no own node, spring or arrows at that step. G.link(G2) keeps it in
% step with plot_pvcurve, plot_diagram and the other plots of the steps. A result without
% the data of the steps stops with GUILDA:ResultCPF:NoStepData.
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% net.initialize();
% res = net.calculate_continuation_powerflow(LoadBus="B005");
% G = res.plot_spring_model();
% G.link(res.plot_pvcurve());
% G.animate();
% ```
%
% See also ResultODE.plot_spring_model, GraphSpring2D, GraphSpring3D, Component.get_spring_node, ResultCPF.plot_diagram
    arguments (Input)
        obj
        opt.Dimension (1,1) double {mustBeMember(opt.Dimension, [2, 3])} = 2  % 2: phasor plane (GraphSpring2D); 3: surface z = log|V| (GraphSpring3D).
        opt.Parent = []  % Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure.
    end
    arguments (Output)
        G  % The picture: a GraphSpring2D or GraphSpring3D object.
    end
    check_step_data(obj, "plot_spring_model", ["tab_variable", "rm_variable", "cm_Vbus", "cm_Icomponent", "sct_network"]);

    a_bus  = reshape(obj.sct_network.a_Bus, [], 1);
    n_bus  = numel(a_bus);
    sv_net = string(cellfun(@(b) b.s_tag, a_bus, "UniformOutput", false));
    [~, iv_row] = ismember(sv_net, obj.sv_bus);
    tab    = obj.tab_variable;
    sv_key = string(tab.Kind) + "|" + string(tab.Owner) + "|" + string(tab.Bus);
    rm_tr  = obj.rm_variable.';                  % variables x steps

    sct_val = step_sample(obj);
    sct_val.cm_V = obj.cm_Vbus(iv_row, :);
    sct_val.cm_I = complex(zeros(n_bus, numel(obj.rv_lambda)));
    sct_val.c_x  = cell(n_bus, 1);
    sct_val.c_u  = cell(n_bus, 1);
    i_comp = 0;
    for i = 1:n_bus
        a_comp = reshape(a_bus{i}.a_Component, [], 1);
        n_comp = numel(a_comp);
        cm_Ic = obj.cm_Icomponent(i_comp + (1:n_comp), :);
        sct_val.cm_I(i, :) = sum(cm_Ic, 1, "omitnan");
        i_comp = i_comp + n_comp;
        sct_val.c_x{i} = cell(n_comp, 1);
        sct_val.c_u{i} = cell(n_comp, 1);
        for j = 1:n_comp
            s_own = string(a_comp{j}.s_tag) + "|" + sv_net(i);
            sct_val.c_x{i}{j} = rm_tr(sv_key == "x|" + s_own, :);
            sct_val.c_u{i}{j} = rm_tr(sv_key == "u|" + s_own, :);
        end
    end
    sct_data = tools.spring_model_data(obj.sct_network, sct_val);
    sct_data.s_sampleName  = sct_val.s_sampleName;
    sct_data.sv_sampleText = sct_val.sv_sampleText;

    if opt.Dimension == 2
        G = GraphSpring2D(sct_data, Parent=opt.Parent);
    else
        G = GraphSpring3D(sct_data, Parent=opt.Parent);
    end
end
