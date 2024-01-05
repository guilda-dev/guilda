function set_init_option_table(app,data)
    if nargin<2
        data = app.net.information('do_report',false);
    end
    app.init_set_table.ColumnName = data.x_equilibrium.component.Properties.VariableNames;
    app.init_set_table.RowName    = data.x_equilibrium.component.Properties.RowNames;
    % temp = data.x_equilibrium{:,[1,3:end]};
    % temp1 = temp(:,1);
    % temp2 = temp(:,2:end); temp2(~isnan(temp2)) = 0;
    % temp = [temp1,temp2];
    xst = data.x_equilibrium.component.Variables;
    app.init_set_table.Data = array2table(string(xst));
    app.init_set_table.ColumnEditable = [false,true(1,size(xst,2))];
end