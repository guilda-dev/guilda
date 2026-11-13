function G = plot_spring_model(obj, opt)
% Draw the power flow solution as a spring-mass picture of the buses.
%
% The nodes are the bus voltage phasors (Vphasor of tab_bus) and the springs are the
% branches. The result holds no states of the components, so there are no own nodes (such
% as the internal voltage of a generator): each bus with a component gets one arrow pair,
% the active power P and the reactive-current magnitude Iq of its injection (Iphasor) at
% the bus voltage. Marker, MarkerSize and Color of the graph parameters of the buses set
% the appearance. Dimension=2 draws the phasor plane (GraphSpring2D), Dimension=3 the
% surface z = log|V| (GraphSpring3D). It reads only the stored result and its network
% snapshot. For the own nodes, draw the equilibrium with PowerNetwork.plot_spring_model.
%
% <@Examples>
% ```matlab
% res = network.IEEE9bus().calculate_powerflow();
% G = res.plot_spring_model();
% G = res.plot_spring_model(Dimension=3);
% ```
%
% See also PowerNetwork.plot_spring_model, ResultODE.plot_spring_model, GraphSpring2D, GraphSpring3D
    arguments (Input)
        obj
        opt.Dimension (1,1) double {mustBeMember(opt.Dimension, [2, 3])} = 2 % 2: phasor plane (GraphSpring2D); 3: surface z = log|V| (GraphSpring3D).
        opt.Parent = [] % Axes to draw in; [] for new axes in a new figure. <@Type> matlab.graphics.axis.Axes
    end
    arguments (Output)
        G % The picture: a GraphSpring2D or GraphSpring3D object.
    end
    if height(obj.tab_bus) == 0 || ~isfield(obj.sct_network, "a_Bus") || ~isfield(obj.sct_network, "a_Branch")
        error(msg("GUILDA:ResultPF:NoSpringData"));
    end

    sv_bus = string(cellfun(@(b) b.s_tag, reshape(obj.sct_network.a_Bus, [], 1), "UniformOutput", false));
    [~, iv_row] = ismember(sv_bus, string(obj.tab_bus.Properties.RowNames));
    sct_val = struct();
    sct_val.rv_t = 0;
    sct_val.cm_V = obj.tab_bus.Vphasor(iv_row);
    sct_val.cm_I = obj.tab_bus.Iphasor(iv_row);
    sct_data = tools.spring_model_data(obj.sct_network, sct_val, OwnNode=false);

    if opt.Dimension == 2
        G = GraphSpring2D(sct_data, Parent=opt.Parent);
    else
        G = GraphSpring3D(sct_data, Parent=opt.Parent);
    end
end
