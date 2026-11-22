function [G, G_chart] = plot_spring_model(obj, opt)
% Draw the time response as a spring-mass picture that can be animated.
%
% The picture holds every output time rv_t: G.set_time(t) shows one time, G.animate()
% plays it and G.export_video(file) writes it as a video. The nodes are voltage phasors:
% every bus, and the own node of each component whose class returns one from its Static
% get_spring_node (the internal voltage of a generator, joined to its bus by the machine
% reactance). The springs are the branches and these reactances. Arrow pairs show the
% active power P and the reactive-current magnitude Iq: on each own node, and on each bus
% with a component without an own node (the bus injection minus the currents of the own
% nodes, at the bus voltage). Marker, MarkerSize and Color of the graph parameters set the
% appearance. Dimension=2 draws the phasor plane (GraphSpring2D), Dimension=3 the surface
% z = log|V| (GraphSpring3D).
%
% Beside the picture, on its right, the side chart G_chart (GraphChart) draws a trajectory
% against time as plot_trajectory, with a cursor at the time shown: by default the omega
% of the generators (the components with the state omega); Trajectory names another
% quantity as Quantity of plot_trajectory ("Vabs", "Vangle", "P", "Q" or a state, input or
% output name). The container (a new figure of 1400 x 600 px when Parent is empty; a
% uigridlayout gets a borderless uipanel first) holds two borderless panels: the picture
% with its playback bar on the left (60 %) and the chart on the right (40 %). The two are
% linked (G.link(G_chart)): the bar, G.set_time, G.play and G.animate move the cursor of the
% chart. The chart has no bar of its own (its time only moves the cursor). Trajectory="none",
% or an axes or uiaxes as Parent, draws the picture alone, without a side chart (G_chart []).
%
% It reads only the stored result: the trajectories of the states, inputs, bus voltages
% and bus currents, and the network snapshot sct_network (class and dynamic parameters of
% each component). While a unit is tripped its states are NaN: its own node, its spring
% and its arrows are not drawn at those times, and the arrow of its bus counts its current
% as 0. The dashed circle |E| of an own node is drawn when |E| stays constant over the
% times (e.g. a classical generator without AVR).
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% sc = net.add_scenario("fault");
% sc.add_fault("B007", [1, 1.05]);
% res = net.simulate("fault", Time=[0, 5]);
% [G, G_chart] = res.plot_spring_model(Dimension=3);   % omega of the generators on the right
% G.animate(Speed=0.5);                                % the cursor of G_chart follows
% G.export_video("swing.mp4");
% G = res.plot_spring_model(Trajectory="none");        % the picture alone
% ```
%
% See also ResultODE.plot_trajectory, PowerNetwork.plot_spring_model, ResultPF.plot_spring_model, GraphSpring2D, GraphSpring3D, Component.get_spring_node
    arguments (Input)
        obj
        opt.Dimension (1,1) double {mustBeMember(opt.Dimension, [2, 3])} = 2  % 2: phasor plane (GraphSpring2D); 3: surface z = log|V| (GraphSpring3D).
        opt.Trajectory (1,1) string = "auto"  % Quantity of the side chart as Quantity of plot_trajectory; "auto": omega of the generators; "none": no side chart.
        opt.Parent = []  % Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure.
    end
    arguments (Output)
        G        % The picture: a GraphSpring2D or GraphSpring3D object.
        G_chart  % The side chart of the trajectory (GraphChart) linked to G; [] without one.
    end
    if isempty(obj.rv_t) || isempty(obj.c_index) || ~isfield(obj.sct_network, "a_Branch")
        error(msg("GUILDA:ResultODE:NoSpringData"));
    end

    n_bus   = numel(obj.sv_bus);
    rm_tr   = obj.rm_variable.';                 % variables x time
    sct_val = struct();
    sct_val.rv_t = obj.rv_t.';
    sct_val.cm_V = complex(zeros(n_bus, numel(obj.rv_t)));
    sct_val.cm_I = obj.rm_I(:, 1:2:end).' + 1j*obj.rm_I(:, 2:2:end).';
    sct_val.c_x  = cell(n_bus, 1);
    sct_val.c_u  = cell(n_bus, 1);
    for i = 1:n_bus
        s = obj.c_index{i};
        sct_val.cm_V(i, :) = [1, 1j]*rm_tr(s.iv_V, :);
        sct_val.c_x{i} = cellfun(@(iv) rm_tr(iv, :), s.c_x(:), "UniformOutput", false);
        sct_val.c_u{i} = cellfun(@(iv) rm_tr(iv, :), s.c_u(:), "UniformOutput", false);
    end
    sct_data = tools.spring_model_data(obj.sct_network, sct_val);

    if opt.Dimension == 2
        fcn_graph = @(h) GraphSpring2D(sct_data, Parent=h);
    else
        fcn_graph = @(h) GraphSpring3D(sct_data, Parent=h);
    end
    [G, G_chart] = draw_with_chart(obj, opt.Parent, opt.Trajectory, "omega", fcn_graph);
end
