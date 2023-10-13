function when_gen_parameter_table_edit(app,event)

    cidx = event.Indices;
    bus_idx = cidx;
    % bus_idx = app.gen_parameter_table.Data{cidx(1),'bus_idx'};
    para_name = app.gen_parameter_table.ColumnName{cidx(2)};
    if ~isnan(event.PreviousData)
        app.culc_powerflow_Lamp.Color = [1,0,0];
        pause(10^(-5));
        app.net.a_bus{bus_idx}.component.parameter{1,para_name} = event.NewData;
        app.net.initialize;
        data = simulation.net_info.look_para(app.net,false);
        app.power_flow_table.Data          = data.flow_para;
        app.equilibrium_table.Data         = data.x_equilibrium;
        app.disp(">> net.a_bus{"+num2str(bus_idx)+"}.component.parameter{1,'"+para_name+"'}="+num2str(event.NewData)+';')
        app.disp('>> net.initialize;')
        app.net_changed_color_switch = true;
        app.refresh_network_graph;
        app.culc_powerflow_Lamp.Color = [0.8,0.8,0.8];
    else
        app.gen_parameter_table.Data{cidx(1),cidx(2)} = event.PreviousData;
        switch app.LanguageSwitch.Value
            case '日本語'
                app.disp('>> エラー:対象のセルは編集できません')
            case 'English'
                app.disp('>> error:Target cell cannot be edited')
        end
    end

end