function [G, G_chart] = plot_diagram(obj, opt)
% Draw the time response as a network diagram (GraphNetDiagram; 2D, or Dimension="3D") with every output time.
%
% The diagram holds every output time rv_t; G.set_time(t) shows the sample nearest to t
% (the first one is shown at first). The bus voltages come from the variables Vre, Vim of
% the buses (rm_variable) and the current of each component from rm_Icomponent, so the
% colors, labels and arrows of the components and branches show the simulated values.
% The current injection of a bus is the sum of the currents of its components: during a
% fault it does not hold the fault current. The branch flows use the admittance matrix
% of each branch in the branch states of the phase of each time (sct_branchY; a result
% built without it: the closed matrices cm_Y of sct_network): an opened
% branch ("6open") carries no current, a branch with one circuit open ("3open") the
% current of the other circuits, and during a fault inside a branch the two ends carry
% the currents of the faulted branch into the fault point (both ends feed it). At a phase
% boundary the end of one phase takes the states of that phase and the start of the
% next those of the next. While a unit is tripped its current is
% NaN: its link is gray, its values are NaN and its bus counts its current as 0. A result
% without component currents (rm_Icomponent all NaN, e.g. a result built without them)
% stops with GUILDA:ResultODE:NoDiagramData. It reads only the stored result. The other
% Name-Value options set the properties of the GraphNetDiagram.
%
% Beside the diagram, on its right, the side chart G_chart (GraphChart) draws a trajectory
% against time as plot_trajectory, with a cursor at the time shown: by default |V| of all
% buses ("Vabs"); Trajectory names another quantity as Quantity of plot_trajectory
% ("Vangle", "P", "Q" or a state, input or output name such as "omega"). The container (a
% new figure of 1400 x 600 px when Parent is empty; a uigridlayout gets a borderless
% uipanel first) holds two borderless panels: the diagram with its playback bar on the
% left (60 %) and the chart on the right (40 %). The two are linked (G.link(G_chart)): the
% bar, G.set_time, G.play and G.animate move the cursor of the chart. The chart has no bar
% of its own (its time only moves the cursor). Trajectory="none", or an axes or uiaxes as
% Parent, draws the diagram alone, without a side chart (G_chart []).
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% sc = net.add_scenario("fault");
% sc.add_fault("B007", [1, 1.05]);
% res = net.simulate("fault", Time=[0, 5]);
% [G, G_chart] = res.plot_diagram(ColorMode="P", LabelMode="value");   % |V| of the buses on the right
% G.set_time(1.02);       % during the fault; the cursor of G_chart moves too
% G = res.plot_diagram(Trajectory="none");    % the diagram alone
% ```
%
% See also ResultODE.plot_trajectory, PowerNetwork.plot_diagram, ResultPF.plot_diagram, GraphNetDiagram, ResultODE.plot_spring_model
    arguments (Input)
        obj
        opt.?GraphNetDiagram  % Name-Value options; each sets the property of the same name of the GraphNetDiagram.
        opt.Trajectory (1,1) string = "auto"  % Quantity of the side chart as Quantity of plot_trajectory; "auto": "Vabs" of all buses; "none": no side chart.
        opt.Parent = []       % Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure.
    end
    arguments (Output)
        G        % GraphNetDiagram object of the drawing.
        G_chart  % The side chart of the trajectory (GraphChart) linked to G; [] without one.
    end
    if isempty(obj.rv_t) || isempty(obj.c_index) || ~isfield(obj.sct_network, "a_Branch") ...
            || (~isempty(obj.rm_Icomponent) && all(isnan(obj.rm_Icomponent), "all"))
        error(msg("GUILDA:ResultODE:NoDiagramData"));
    end

    n_bus = numel(obj.sv_bus);
    rm_tr = obj.rm_variable.';                   % variables x time
    cm_V  = complex(zeros(n_bus, numel(obj.rv_t)));
    for i = 1:n_bus
        cm_V(i, :) = [1, 1j]*rm_tr(obj.c_index{i}.iv_V, :);
    end
    sct_state = struct("rv_t", obj.rv_t.', "cm_Vbus", cm_V, ...
        "cm_Icomp", obj.rm_Icomponent(:, 1:2:end).' + 1j*obj.rm_Icomponent(:, 2:2:end).');
    if ~isempty(obj.sct_branchY.c_Ybranch)
        sct_state.c_Ybranch  = obj.sct_branchY.c_Ybranch;
        sct_state.iv_Ybranch = obj.sct_branchY.iv_Y;
    end

    c_opt = namedargs2cell(rmfield(opt, ["Trajectory", "Parent"]));
    [G, G_chart] = draw_with_chart(obj, opt.Parent, opt.Trajectory, "Vabs", ...
        @(h) GraphNetDiagram(obj.sct_network, sct_state, c_opt{:}, Parent=h));
end
