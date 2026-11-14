function G = plot_diagram(obj, opt)
% Draw the power flow solution as a 3D network diagram (DrawerNetDiagram).
%
% The bus voltages are Vphasor of tab_bus. The result holds no current of each component,
% so the bus injection P + jQ is split among the components of the bus as initialize
% would split it (tools.distribute_power with "baseMVA": tab_parameter.powerflow of the
% snapshot, the slack remainder and the split of the bus Q), and each component current is
% conj((P + jQ) / V). The branch flows come from the admittance matrix cm_Y of each branch
% in the snapshot. It reads only the stored result and its network snapshot. The other
% Name-Value options set the properties of the DrawerNetDiagram.
%
% <@Examples>
% ```matlab
% res = network.IEEE14bus().calculate_powerflow();
% G = res.plot_diagram();
% G = res.plot_diagram(ColorMode="P", LabelMode="value");
% ```
%
% See also PowerNetwork.plot_diagram, DrawerNetDiagram, ResultPF.plot_network
    arguments (Input)
        obj
        opt.?DrawerNetDiagram % Name-Value options; each sets the property of the same name of the DrawerNetDiagram.
        opt.Parent = []       % Axes to draw in; [] for new axes in a new figure. <@Type> matlab.graphics.axis.Axes
    end
    arguments (Output)
        G % DrawerNetDiagram object of the drawing.
    end
    sct_net = obj.sct_network;
    if height(obj.tab_bus) == 0 || ~isfield(sct_net, "a_Bus") || ~isfield(sct_net, "a_Branch")
        error(msg("GUILDA:ResultPF:NoNetworkSnapshot"));
    end

    a_bus  = reshape(sct_net.a_Bus, [], 1);
    sv_bus = string(cellfun(@(b) b.s_tag, a_bus, "UniformOutput", false));
    [~, iv_row] = ismember(sv_bus, string(obj.tab_bus.Properties.RowNames));
    cv_V = obj.tab_bus.Vphasor(iv_row);
    lv_slack = cellfun(@(b) b.l_isSlack, a_bus);
    if ismember("Type", obj.tab_PFcondition.Properties.VariableNames)
        [~, iv_pf] = ismember(sv_bus, string(obj.tab_PFcondition.Properties.RowNames));
        lv_slack(iv_pf > 0) = obj.tab_PFcondition.Type(iv_pf(iv_pf > 0)) == "slack";
    end
    c_Icomp = cell(numel(a_bus), 1);
    for i = 1:numel(a_bus)
        rm_PQ = tools.distribute_power(a_bus{i}, obj.tab_bus.P(iv_row(i)), obj.tab_bus.Q(iv_row(i)), "baseMVA", lv_slack(i));
        c_Icomp{i} = conj((rm_PQ(:,1) + 1j*rm_PQ(:,2)) / cv_V(i));
    end
    sct_state = struct("rv_t", 0, "cm_Vbus", cv_V, "cm_Icomp", vertcat(c_Icomp{:}, zeros(0,1)));

    c_opt = namedargs2cell(opt);
    G = DrawerNetDiagram(sct_net, sct_state, c_opt{:});
end
