function G = plot_spring_model(obj, opt)
% Draw the equilibrium of the network as a spring-mass picture.
%
% The nodes are voltage phasors: every bus, and the own node of each component whose class
% returns one from its Static get_spring_node (the internal voltage of a generator, joined
% to its bus by the machine reactance). The springs are the branches and these reactances.
% Arrow pairs show the active power P and the reactive-current magnitude Iq: on each own
% node, and on each bus with a component without an own node (the bus injection minus the
% currents of the own nodes, at the bus voltage). Marker, MarkerSize and Color of the graph
% parameters of the buses and components set the appearance. Dimension=2 draws the phasor
% plane (GraphSpring2D), Dimension=3 the surface z = log|V| (GraphSpring3D).
%
% The picture shows the equilibrium of initialize: c_Vequilibrium and c_Iequilibrium of the
% buses, rv_Xequilibrium and rv_Uequilibrium of the components. It needs an up-to-date
% network: before net.initialize(), or after an edit that made a layer stale, it stops with
% GUILDA:PowerNetwork:SpringModelStale ("Run net.initialize() first"). To draw the result of
% an analysis, use ResultODE.plot_spring_model (animation) or ResultPF.plot_spring_model.
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% G = net.plot_spring_model();               % phasor plane
% G = net.plot_spring_model(Dimension=3);    % on the surface z = log|V|
% G.ShowValue = false;
% ```
%
% See also ResultODE.plot_spring_model, ResultPF.plot_spring_model, GraphSpring2D, GraphSpring3D, Component.get_spring_node
%
% <@Group> Queries and display
    arguments (Input)
        obj
        opt.Dimension (1,1) double {mustBeMember(opt.Dimension, [2, 3])} = 2 % 2: phasor plane (GraphSpring2D); 3: surface z = log|V| (GraphSpring3D).
        opt.Parent = [] % Axes to draw in; [] for new axes in a new figure. <@Type> matlab.graphics.axis.Axes
    end
    arguments (Output)
        G % The picture: a GraphSpring2D or GraphSpring3D object.
    end
    simulateFcn_check(obj, "GUILDA:PowerNetwork:SpringModelStale");

    sct_net = struct(obj, false);
    a_bus   = reshape(sct_net.a_Bus, [], 1);
    sct_val = struct();
    sct_val.rv_t = 0;
    sct_val.cm_V = cellfun(@(b) b.c_Vequilibrium, a_bus);
    sct_val.cm_I = cellfun(@(b) b.c_Iequilibrium, a_bus);
    sct_val.c_x  = cellfun(@(b) cellfun(@(c) c.rv_Xequilibrium, reshape(b.a_Component, [], 1), "UniformOutput", false), ...
                           a_bus, "UniformOutput", false);
    sct_val.c_u  = cellfun(@(b) cellfun(@(c) c.rv_Uequilibrium, reshape(b.a_Component, [], 1), "UniformOutput", false), ...
                           a_bus, "UniformOutput", false);
    sct_data = tools.spring_model_data(sct_net, sct_val);

    if opt.Dimension == 2
        G = GraphSpring2D(sct_data, Parent=opt.Parent);
    else
        G = GraphSpring3D(sct_data, Parent=opt.Parent);
    end
end
