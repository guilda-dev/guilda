function refresh(app,data)
    if nargin<2
        data = app.net.information('do_report',false);
    end
    
    app.power_flow_table.ColumnName = {'type','RealPower','ReactivePower','Vabs','Varg','Iabs','Iarg'};%data.flow_para.Properties.VariableNames;
    app.power_flow_table.RowName    = "bus" + (1:numel(app.net.a_bus))';

    class_bus = tools.vcellfun(@(b) string(cut(class(b))), app.net.a_bus);
    flow_data = string(data.bus{:,{'RealPower','ReactivePower','Vabs','Varg','Iabs','Iarg'}});

    app.power_flow_table.Data          = [class_bus,flow_data];
    app.power_flow_table.ColumnEditable = logical([0,1,1,1,1,0,0]);

    s = uistyle('BackgroundColor',[0.97,0.88,0.66]);
    for i = 1:numel(app.net.a_bus)
        para_idx = tools.hcellfun(@(b) find(strcmp({'P','Q','Vabs','Vangle'},b)),properties(app.net.a_bus{i}));
        if ~isa(app.net.a_bus{i}.component,'component_empty')
            arrayfun(@(pidx) addStyle(app.power_flow_table,s,'cell',[i,1+pidx]),para_idx);
        end
    end
    
    app.equilibrium_table.ColumnName = [{'class'},data.x_equilibrium.component.Properties.VariableNames];
    app.equilibrium_table.RowName    = data.x_equilibrium.component.Properties.RowNames;
    type = tools.vcellfun(@(b) string(class(b.component)), app.net.a_bus);
    app.equilibrium_table.Data       = [type,string(data.x_equilibrium.component.Variables)];

    app.gen_parameter_table.ColumnName = [{'class'},data.parameter.component.Properties.VariableNames];
    app.gen_parameter_table.RowName    = data.parameter.component.Properties.RowNames;
    app.gen_parameter_table.Data       = [type,string(data.parameter.component.Variables)];
    app.gen_parameter_table.ColumnEditable = true(1,size(data.parameter.component,2));
    

    app.branch_table.ColumnName = {'type','bus_from','bus_to','x','y','phase','tap'};
    type = data.branch{:,'class'};
    type = tools.varrayfun(@(d) string(cut(char(type(d)))),  1:numel(type));
    app.branch_table.Data       = [type,string(data.branch{:,2:6})];
    app.branch_table.ColumnEditable = logical([0,0,0,1,1,1,1]);
    

    set_init_option_table(app)
    app.net_changed_switch =true;
    refresh_network_graph(app);
end

function name = cut(name)
    idx = find(name=='.',1,"last");
    if ~isempty(idx)
        name = name(idx+1:end);
    end
end
