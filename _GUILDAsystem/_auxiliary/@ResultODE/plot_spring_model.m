function G = plot_spring_model(obj, opt)
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
% G = res.plot_spring_model(Dimension=3);
% G.animate(Speed=0.5);
% G.export_video("swing.mp4");
% ```
%
% See also PowerNetwork.plot_spring_model, ResultPF.plot_spring_model, GraphSpring2D, GraphSpring3D, Component.get_spring_node
    arguments (Input)
        obj
        opt.Dimension (1,1) double {mustBeMember(opt.Dimension, [2, 3])} = 2 % 2: phasor plane (GraphSpring2D); 3: surface z = log|V| (GraphSpring3D).
        opt.Parent = [] % Axes to draw in; [] for new axes in a new figure. <@Type> matlab.graphics.axis.Axes
    end
    arguments (Output)
        G % The picture: a GraphSpring2D or GraphSpring3D object.
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
        G = GraphSpring2D(sct_data, Parent=opt.Parent);
    else
        G = GraphSpring3D(sct_data, Parent=opt.Parent);
    end
end
