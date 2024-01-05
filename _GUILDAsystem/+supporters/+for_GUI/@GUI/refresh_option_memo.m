function refresh_option_memo(app)
    app.simulate_time(1) = str2num(app.simulate_time_start.Value);
    app.simulate_time(2) = str2num(app.simulate_time_end.Value);
    switch app.LanguageSwitch.Value
        case '日本語'
            memo = {['simulation時間：',app.simulate_time_start.Value,'(s)~',...
                                       app.simulate_time_end.Value  ,'(s)']};
        case 'English'
            memo = {['simulation Time：',app.simulate_time_start.Value,'(s)~',...
                           app.simulate_time_end.Value  ,'(s)']};
    end
    memo = [memo;{app.ButtonGroup.SelectedObject.Text};{' '}];

    %%初期値応答
    memo = [memo;{['・',app.init_set.Title]}];
    ttext = false;
    for i = 1:numel(app.init_set_table.Data{:,1})
        init_temp = app.init_set_table.Data{i,1:end};
        varname = app.init_set_table.ColumnName;
        varname_i = app.net.a_bus{i}.component.get_state_name;
        for j = 1:numel(init_temp)
            para_idx = find(strcmp(varname_i,varname{j}));
            xst_j = app.net.a_bus{i}.component.x_equilibrium(para_idx);
            if numel(str2num(init_temp(j)))==0
                if ~isempty(para_idx)   
                    app.init_set_table.Data{i,para_idx} = num2str(xst_j);
                end
            else
                val =str2num(init_temp(j)) - xst_j;
                if val>=1e-4
                    val = num2str(val);
                    switch app.LanguageSwitch.Value
                        case '日本語'
                            memo = [memo;{['  母線',num2str(i),'の',varname{j},'を',val,',']}];
                        case 'English'
                            if ~ttext
                                memo = [memo;{'  the point where'}];
                            end
                            memo = [memo;{['  the ',varname{j},' of bus',num2str(i),'is shifted by ',val,',']}];
                    end
                    ttext = true; 
                end
            end
        end
    end
    if ttext
        switch app.LanguageSwitch.Value
            case '日本語'
                memo = [memo;{'  だけ平衡点からずらした初期値.'}];
            case 'English'
                memo = [memo;{'  from the equilibrium point.'}];
        end
    else
        switch app.LanguageSwitch.Value
            case '日本語'
                memo = [memo;{'  初期値は平衡点のまま'}];
            case 'English'
                memo = [memo;{'  Initial value is the equilibrium point.'}];
        end
    end

    %%地絡応答
    memo = [memo;{' '};{['・',app.fault_set.Title]}];
    ttext = false;
    for i = 1:numel(app.fault_set_table.Data{:,1})
        idx_temp  = app.fault_set_table.Data{i,:};
        checkj = arrayfun(@(j) ~numel(str2num(idx_temp(j)))==0, 1:numel(idx_temp));
        if all(checkj)
            fault_temp = app.fault_set_table.Data{i,:};
            if  ~ttext
                memo = [memo;{'  Ground fault occurs'}];
            end
            switch app.LanguageSwitch.Value
                case '日本語'
                    memo = [memo;{['  母線',num2str(fault_temp{3}),'に',...
                            num2str(fault_temp{1}),'~',num2str(fault_temp{2}),'秒の間発生']}];
                case 'English'
                    memo = [memo;{['  bus ',num2str(fault_temp{3}),' : between ',...
                            num2str(fault_temp{1}),' ~ ',num2str(fault_temp{2}),'seconds']}];
            end
            ttext = true;
        end
    end
    if ~ttext
        switch app.LanguageSwitch.Value
            case '日本語'
                memo = [memo;{'  なし'}];
            case 'English'
                memo = [memo;{'  There is no fault.'}];
        end
    end

    %%%入力応答
    memo = [memo;{' '};{['・',app.U_set.Title]}];
    ttext = false;
    U_temp = app.U_set_Table.Data{1,{'u','u_idx'}};
    if ~numel(str2num(U_temp(2)))==0
        switch app.LanguageSwitch.Value
            case '日本語'
                memo = [memo;{['  母線',num2str(U_temp{2}),'に入力が加えられている．']}];
            case 'English'
                memo = [memo;{['  add input to bus',num2str(U_temp{2})]}];
        end
        ttext = true;
    end
    if ~ttext
        switch app.LanguageSwitch.Value
            case '日本語'
                memo = [memo;{'  定常値のまま'}];
            case 'English'
                memo = [memo;{'  No input.'}];
        end
    end
    app.option_memo.Value = memo;

    app.switch_out_lamp_mode(false);
    app.switch_SimulationRun_Button(true);
    app.switch_PlotOut_Button(false);
end