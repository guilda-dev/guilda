function G = plot_diagram(obj, opt)
% Draw the 3D network diagram of the equilibrium: buses, branches and components as solids.
%
% The diagram shows the equilibrium of initialize: c_Vequilibrium of the buses and
% c_Iequilibrium of the components. It is built from the snapshot struct(obj, false) and
% does not change the network; positions from the automatic layout stay in the drawing.
% It needs an up-to-date network: before net.initialize(), or after an edit that made a
% layer stale, it stops with GUILDA:PowerNetwork:DiagramStale ("Run net.initialize()
% first"). The other Name-Value options set the properties of the DrawerNetDiagram. To
% draw a power flow solution, use ResultPF.plot_diagram.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% G = net.plot_diagram();
% G = net.plot_diagram(ColorMode="P", BusHeightMode="V");
% ```
%
% See also DrawerNetDiagram, ResultPF.plot_diagram, PowerNetwork.plot_spring_model
%
% <@Group> Queries and display
    arguments (Input)
        obj
        opt.?DrawerNetDiagram % Name-Value options; each sets the property of the same name of the DrawerNetDiagram.
        opt.Parent = []       % Axes to draw in; [] for new axes in a new figure. <@Type> matlab.graphics.axis.Axes
    end
    arguments (Output)
        G % DrawerNetDiagram object of the drawing.
    end
    simulateFcn_check(obj, "GUILDA:PowerNetwork:DiagramStale");

    sct_net = struct(obj, false);
    a_bus   = reshape(sct_net.a_Bus, [], 1);
    sct_state = struct();
    sct_state.rv_t     = 0;
    sct_state.cm_Vbus  = cellfun(@(b) b.c_Vequilibrium, a_bus);
    c_Icomp            = cellfun(@(b) cellfun(@(c) c.c_Iequilibrium, reshape(b.a_Component, [], 1)), ...
                                 a_bus, "UniformOutput", false);
    sct_state.cm_Icomp = vertcat(c_Icomp{:}, zeros(0, 1));

    c_opt = namedargs2cell(opt);
    G = DrawerNetDiagram(sct_net, sct_state, c_opt{:});
end
