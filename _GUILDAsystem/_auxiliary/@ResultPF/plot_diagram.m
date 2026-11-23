function G = plot_diagram(obj, opt)
% Draw the power flow solution as a network diagram (GraphNetDiagram; 2D, or Dimension="3D").
%
% The bus voltages are Vphasor of tab_bus. The result holds no current of each component,
% so the bus injection P + jQ is split among the components of the bus as initialize
% would split it (tools.distribute_power with "baseMVA": tab_parameter.powerflow of the
% snapshot, the remainder at the slack bus (l_isSlack of the snapshot) and the split of
% the bus Q), and each component current is
% conj((P + jQ) / V). The branch flows come from the admittance matrix cm_Y of each branch
% in the snapshot. It reads only the stored result and its network snapshot. The other
% Name-Value options set the properties of the GraphNetDiagram.
%
% <@Examples>
% ```matlab
% res = network.IEEE14bus().calculate_powerflow();
% G = res.plot_diagram();
% G = res.plot_diagram(ColorMode="P", LabelMode="value");
% ```
%
% See also PowerNetwork.plot_diagram, ResultODE.plot_diagram, GraphNetDiagram, ResultPF.plot_single_line_diagram
    arguments (Input)
        obj
        opt.?GraphNetDiagram  % Name-Value options; each sets the property of the same name of the GraphNetDiagram.
        opt.Parent = []       % Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure.
    end
    arguments (Output)
        G  % GraphNetDiagram object of the drawing.
    end
    sct_net = obj.sct_network;
    if height(obj.tab_bus) == 0 || ~isfield(sct_net, "a_Bus") || ~isfield(sct_net, "a_Branch")
        error(msg("GUILDA:ResultPF:NoNetworkSnapshot"));
    end

    a_bus  = reshape(sct_net.a_Bus, [], 1);
    sv_bus = string(cellfun(@(b) b.s_tag, a_bus, "UniformOutput", false));
    [~, iv_row] = ismember(sv_bus, string(obj.tab_bus.Properties.RowNames));
    cv_V = obj.tab_bus.Vphasor(iv_row);
    c_Icomp = cell(numel(a_bus), 1);
    for i = 1:numel(a_bus)
        rm_PQ = tools.distribute_power(a_bus{i}, obj.tab_bus.P(iv_row(i)), obj.tab_bus.Q(iv_row(i)), "baseMVA");
        c_Icomp{i} = conj((rm_PQ(:,1) + 1j*rm_PQ(:,2)) / cv_V(i));
    end
    sct_state = struct("rv_t", 0, "cm_Vbus", cv_V, "cm_Icomp", vertcat(c_Icomp{:}, zeros(0,1)));

    c_opt = namedargs2cell(opt);
    G = GraphNetDiagram(sct_net, sct_state, c_opt{:});
end
