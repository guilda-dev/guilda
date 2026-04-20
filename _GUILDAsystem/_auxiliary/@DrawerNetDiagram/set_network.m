function set_network(obj, net)
    a_bus        = net.a_Bus;
    a_branch     = net.a_Branch;
    obj.n_bus    = numel(a_bus);
    obj.n_branch = numel(a_branch);
    obj.n_component = sum(tools.vcellfun(@(b) numel(b.a_Component), a_bus));
    
    Ymat = net.get_admittance_matrix();
    obj.cm_Ymat        = sparse(Ymat.Variables);
    obj.tab_bus        = tools.vcellfun(@(b) b.tab_parameter, a_bus);
    obj.tab_branch     = tools.vcellfun(@(b) b.tab_parameter, a_branch);

    % extract component information
    i_comp = 0;
    obj.str_bus       = string(nan(obj.n_bus, 1));
    obj.str_component = string(nan(obj.n_component, 1));
    obj.tab_component = cell(obj.n_component, 1);
    for i = 1:obj.n_bus
        a_busi   = a_bus{i};
        str_busi = string(a_busi);
        a_compi  = a_busi.a_Component;
        n_compi  = numel(a_compi);
        obj.str_bus(i) = str_busi;
        for j = 1:n_compi
            a_compij = a_compi{j};
            i_comp   = i_comp+1;
            obj.str_component(i_comp) = replace(string(a_compij), str_busi, '');
            bus     = i;
            isSlack = a_busi.l_isSlack;
            obj.tab_component{i_comp} = [table(bus,isSlack),a_compij.tab_parameter(:,["operation","powerflow","graph"])];
            if any( isnan( obj.tab_component{i_comp}.graph{:,["Xaxis","Yaxis"]} ))
                % If component graph coordinates are not set, place them near the bus
                diff = 0.05 * exp(1j*2*pi*(j-1)/n_compi); % Spread components around the bus
                obj.tab_component{i_comp}.graph.Xaxis = obj.tab_bus.graph.Xaxis(i) + real(diff);
                obj.tab_component{i_comp}.graph.Yaxis = obj.tab_bus.graph.Yaxis(i) + imag(diff);
            end
        end
    end
    obj.tab_component = vertcat(obj.tab_component{:});

    str_bus2bus        = tools.hcellfun(@(b) string(b.a_Bus), a_branch);
    [~,obj.im_edge]    = ismember(str_bus2bus, obj.str_bus);    

    % If any bus is missing coordinates, use a force-directed layout to determine positions.
    rm_axis = obj.tab_bus.graph{:, ["Xaxis","Yaxis"]};
    if any(isnan(rm_axis(:)), 'all')
        G      = graph(obj.im_edge(1,:), obj.im_edge(2,:), [], obj.str_bus);
        fig    = figure('Visible', 'off');
        h_temp = plot(G, 'Layout', 'force', 'UseGravity', true, 'Iterations', 100);
        x_main = h_temp.XData;
        y_main = h_temp.YData;
        close(fig);
        for i = 1:obj.n_bus
            a_bus{i}.para_graph.Xaxis = x_main(i);
            a_bus{i}.para_graph.Yaxis = y_main(i);
        end
        obj.tab_bus.graph{:, ["Xaxis","Yaxis"]} = [x_main(:), y_main(:)];
    end


    % Precompute matrices for efficient updates during plotting
    obj.str_branch      = string(nan(obj.n_branch, 1));
    obj.cm_Vbus2Ibranch = zeros(obj.n_branch*2, obj.n_bus);
    obj.cm_Vbus2Vbranch = zeros(obj.n_branch*2, obj.n_bus);
    SvdMaxYmat = nan(obj.n_branch, 1);
    for i = 1:obj.n_branch
        obj.str_branch(i)     = string(a_branch{i});
        Ymat_branchi          = a_branch{i}.get_admittance_matrix();
        obj.cm_Vbus2Ibranch(2*i-1:2*i, obj.im_edge(:,i)) = Ymat_branchi;
        obj.cm_Vbus2Vbranch(2*i-1:2*i, obj.im_edge(:,i)) = eye(2);
        SvdMaxYmat(i) = max(svd(Ymat_branchi));
    end
    obj.tab_branch.dynamics = [table(SvdMaxYmat), obj.tab_branch.dynamics];
    obj.cm_Vbus2Ibranch = sparse(obj.cm_Vbus2Ibranch);
    obj.cm_Vbus2Vbranch = sparse(obj.cm_Vbus2Vbranch);


end