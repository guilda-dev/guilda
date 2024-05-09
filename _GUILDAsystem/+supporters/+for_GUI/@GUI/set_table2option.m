function set_table2option(app)
    app.option_command_text = '\n';
    add_command(app,'実行コマンド');
    time = [str2num(app.simulate_time_start.Value),str2num(app.simulate_time_end.Value)];
    app.simulate_time = time;
    add_command(app,['t = ',mat2str(time),';'])
    app.option = struct();
    add_command(app,'option = struct();')

    if app.simulate_mode_nonlinear.Value
        add_command(app,'option.linear = false;')
    else
        add_command(app,'option.linear = true;')
    end

    x_init_switch = true;
    n_state = 0;
    varname = app.init_set_table.ColumnName;
    for i = 1:size(app.init_set_table.Data,1)
        init_temp = app.init_set_table.Data{i,1:end};
        varname_i = app.net.a_bus{i}.component.get_state_name;
        for j  = 1:numel(init_temp)
            if ~numel(str2num(init_temp(j)))==0
                para_idx = find(strcmp(varname_i,varname{j}));
                value = str2num(init_temp(j)) - app.net.a_bus{i}.component.x_equilibrium(para_idx);
                if value>=1e-4
                    if x_init_switch
                        app.option.x0_sys = app.net.x_equilibrium;
                        add_command(app,'option.x0_sys = net.x_equilibrium;')
                        x_init_switch = false;
                    end
                    idx = n_state+para_idx;
                    add_command(app,['option.x0_sys(',num2str(idx),') = option.x0_sys(',num2str(idx),')+',num2str(value),';'])
                    app.option.x0_sys(idx) = app.option.x0_sys(idx)+value;
                end
            end
        end
        n_state = n_state+app.net.a_bus{i}.component.get_nx;
    end

    
    fault_text = '';
    fault_data = {};
    fault_switch = false;
    for i = 1:numel(app.fault_set_table.Data{:,1})
        idx_temp  = app.fault_set_table.Data{i,:};
        checkj = arrayfun(@(j) ~numel(str2num(idx_temp(j)))==0, 1:numel(idx_temp));
        if all(checkj)
            fault_time = [str2num(idx_temp(1)),str2num(idx_temp(2))];
            fault_bus  = str2num(idx_temp(3));
            fault_data = [fault_data(:),{{fault_time,fault_bus}}];
            fault_text = [fault_text,'{',mat2str(fault_time),',[',mat2str(fault_bus),']}'];
            if ~fault_switch
                fault_switch = true;
            end
        end
    end
    if fault_switch
        add_command(app,['option.fault = {',fault_text(1:end-1),'};'])
        app.option.fault = fault_data;
    end

    U_switch = false;
    add_command(app,'入力応答は未実装です．．．')

    if U_switch
        add_aommand(app,'out = net.simulate(t,u,u_idx,option)');
    else
        add_command(app,'out = net.simulate(t,option)')
    end
end

function add_command(app,text_in)
    app.option_command_text = [app.option_command_text,'>> ',text_in,'\n'];
end