function refresh_data_table_color(app)

    %{
    f_addStyle= @(i,tdata) addStyle(tdata,...
                                    uistyle('BackgroundColor',app.network_graph_data.Ncolor{i}),...
                                    'cell',...
                                    [find(tdata.Data{:,'bus_idx'}==i),1]);
    func = @(tdata) arrayfun(@(i) f_addStyle(i,tdata), tdata.Data{:,'bus_idx'}.');
    func(app.power_flow_table)
    func(app.equilibrium_table)
    func(app.gen_parameter_table)
    %}    

    cdata = app.network_graph_data.Ncolor;
    data  = app.power_flow_table.Data;
    for i = 1:size(data,1)
        idx=i; %idx = find(data{:,'bus_idx'}==i);
        addStyle(app.power_flow_table,uistyle('BackgroundColor',k2w(cdata{i})),'cell',[idx,1]);
    end
    data  = app.equilibrium_table.Data;
    for i = 1:size(data,1)
        idx=i; %idx = find(data{:,'bus_idx'}==i);
        addStyle(app.equilibrium_table,uistyle('BackgroundColor',k2w(cdata{i})),'cell',[idx,1]);
    end
    data  = app.gen_parameter_table.Data;
    for i = 1:size(data,1)
        idx=i; %idx = find(data{:,'bus_idx'}==i);
        addStyle(app.gen_parameter_table,uistyle('BackgroundColor',k2w(cdata{i})),'cell',[idx,1]);
    end

end

function c = k2w(c)
    if strcmp(c,'k')
        c = 'w';
    end
end