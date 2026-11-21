function G = plot_diagram(obj, opt)
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
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% sc = net.add_scenario("fault");
% sc.add_fault("B007", [1, 1.05]);
% res = net.simulate("fault", Time=[0, 5]);
% G = res.plot_diagram(ColorMode="P", LabelMode="value");
% G.set_time(1.02);       % during the fault
% ```
%
% See also PowerNetwork.plot_diagram, ResultPF.plot_diagram, GraphNetDiagram, ResultODE.plot_spring_model
    arguments (Input)
        obj
        opt.?GraphNetDiagram  % Name-Value options; each sets the property of the same name of the GraphNetDiagram.
        opt.Parent = []       % Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure.
    end
    arguments (Output)
        G  % GraphNetDiagram object of the drawing.
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

    c_opt = namedargs2cell(opt);
    G = GraphNetDiagram(obj.sct_network, sct_state, c_opt{:});
end
