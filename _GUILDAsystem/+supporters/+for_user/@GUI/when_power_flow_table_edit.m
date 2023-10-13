function when_power_flow_table_edit(app,event)

    cidx = event.Indices;
    bus_idx = cidx(1);
    % bus_idx = app.power_flow_table.Data{cidx(1),'bus_idx'};
    para = {'P','Q','Vabs','Vangle'};
    para_name = para{cidx(2)-1};
    newData = str2double(event.NewData);
    if isprop(app.net.a_bus{bus_idx} ,para_name) && ~isa(app.net.a_bus{bus_idx}.component,'component_empty') && ~isnan(newData)
        app.culc_powerflow_Lamp.Color = [1,0,0];
        pause(10^(-5));
        app.net.a_bus{bus_idx}.(['set_',para_name])(newData);
        app.net.initialize;
        data = supporters.for_user.func.look_para(app.net,false);
        app.power_flow_table.Data          = data.flow_para;
        app.equilibrium_table.Data         = data.x_equilibrium;
        app.disp(['>> net.a_bus{',num2str(bus_idx),'}.',para_name,'=',num2str(event.NewData),';'])
        app.disp('>> net.initialize;')
        app.net_changed_color_switch = true;
        app.refresh_network_graph;
        app.culc_powerflow_Lamp.Color = [0.8,0.8,0.8];
    else
        app.power_flow_table.Data(cidx(1),cidx(2)) = event.PreviousData;
        switch app.LanguageSwitch.Value
            case '日本語'
                app.disp('>> エラー:対象のセルは編集できません')
            case 'English'
                app.disp('>> error:Target cell cannot be edited')
        end
    end

end