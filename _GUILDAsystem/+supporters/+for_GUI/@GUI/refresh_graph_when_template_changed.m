function refresh_graph_when_template_changed(app)
    app.graph_properties_table.Data{:,1} =...
        false(size(app.graph_properties_table.Data,1),1);
    if app.PButton.Value
        setting_for_PQVI(app,'P');
    elseif app.QButton.Value
        setting_for_PQVI(app,'Q');
    elseif app.IButton.Value
        setting_for_PQVI(app,'Iabs');
    elseif app.VButton.Value
        setting_for_PQVI(app,'Vabs');
    elseif app.busButton.Value
        idx = strcmp(app.graph_properties_table.Data{:,'variable'},'bus_PV');
        app.graph_properties_table.Data{idx,1} = true;
        app.graph_properties_table.Data{idx,'Size'} = {'10'};
        app.graph_properties_table.Data(idx,'color') = {'#D95319'};
        app.graph_properties_table.Data(idx,'shape') = {'o'};
        idx = strcmp(app.graph_properties_table.Data{:,'variable'},'bus_PQ');
        app.graph_properties_table.Data{idx,1} = true;
        app.graph_properties_table.Data{idx,'Size'} = {'10'};
        app.graph_properties_table.Data(idx,'color') = {'#0072BD'};
        app.graph_properties_table.Data(idx,'shape') = {'s'};
        idx = strcmp(app.graph_properties_table.Data{:,'variable'},'bus_slack');
        app.graph_properties_table.Data{idx,1} = true;
        app.graph_properties_table.Data{idx,'Size'} = {'15'};
        app.graph_properties_table.Data(idx,'color') = {'#77AC30'};
        app.graph_properties_table.Data(idx,'shape') = {'p'};
    elseif app.componentButton.Value
        color_store = {'#0072BD','#D95319','#EDB120','#7E2F8E','#77AC30','#4DBEEE','#A2142F',...
                       '#FF0000','#00FF00','#0000FF','#FF00FF','#FFFF00','#000000','#00FFFF'};
        class_names = tools.vcellfun(@(b) {class(b.component)},app.net.a_bus);
        class_names = unique(class_names);
        for i = 1:numel(class_names)
            idx = strcmp(app.graph_properties_table.Data{:,'variable'},class_names{i});
            app.graph_properties_table.Data{idx,1} = true;
            app.graph_properties_table.Data{idx,'Size'} = {'10'};
            if rem(i,numel(color_store))==0
                cidx = numel(color_store);
            else
                cidx = rem(i,numel(color_store));
            end
            app.graph_properties_table.Data(idx,'color') = color_store(cidx);
            app.graph_properties_table.Data(idx,'shape') = {'o'};
        end
    end
    app.net_changed_color_switch = true;
    app.refresh_network_graph;
end

function setting_for_PQVI(app,para)
    idx = strcmp(app.graph_properties_table.Data{:,'variable'},'all_bus');
    app.graph_properties_table.Data{:,1} = idx;
    app.graph_properties_table.Data{idx,'Size'} = {para};
    app.graph_properties_table.Data(idx,'color') = {'pm'};
    app.graph_properties_table.Data(idx,'shape') = {'o'};
end