function refresh_network_graph(app)
    if app.net_changed_switch
        refresh_graph_controller_marker_setter(app);
        app.network_graph_data = supporters.for_user.func.look_modelTree(app.net,false);
        app.net_changed_color_switch = true;
        app.net_changed_switch = false;
    end

    if app.net_changed_color_switch
        app.out_changed = true;
        Cset_table = app.graph_properties_table.Data;
        Cset_idx = find(Cset_table{:,1})';
        prior_idx = Cset_table{:,'prior'};
        prior_idx = prior_idx(Cset_idx);
        [~,prior_idx] = sort(prior_idx,'descend');
        Cset_idx = Cset_idx(prior_idx);
        idx = supporters.for_user.func.look_component_type(app.net);
        idx = struct2table(idx);
        temp = false(size(idx{:,1}));
        nan_para_list = cell(numel(app.net.a_bus),1);
        f = @(w) strrep(w,'.','___');
        for i = Cset_idx
            idx_temp = idx{:,f(Cset_table{i,'variable'})};
            app.network_graph_data.Ncolor(idx_temp,:) = Cset_table{i,'color'};
            app.network_graph_data.Nshape(idx_temp,:) = Cset_table{i,'shape'};
            
            tempCsize = Cset_table{i,'Size'};
            tempCsize = tempCsize{:};
            if numel(str2num(tempCsize))~=0
                Cset_table_temp = Cset_table{i,'Size'};
                app.network_graph_data.Nsize(idx_temp,:) = str2num(Cset_table_temp{1});
                nan_para_list(idx_temp) = {'pt'};
            else
                idx_operator = sort(tools.hcellfun(@(pat) strfind(tempCsize,pat),{'/','*','+','-','(',')',filesep}));
                idx_operator = [idx_operator,numel(tempCsize)+1];
                tempCsize = [tempCsize,' '];
                Csize = cell(1,2*numel(idx_operator)+1);
                Csize(2:2:end) = arrayfun(@(b) {tempCsize(b)},idx_operator);
                temp_size = zeros(numel(idx_temp),1);
                for bus_j = find(idx_temp).'
                    pre_idx = 0;
                    nan_para = '';
                    for j = 1:numel(idx_operator)
                        if (pre_idx+1) == idx_operator(j)
                            Csize{2*j-1} = '';
                        else
                            temp_w = tempCsize(pre_idx+1:idx_operator(j)-1);
                            temp_w(temp_w==' ') = [];
                            if numel(str2num(temp_w)) == 0
                                value = func_get_para(app,bus_j,temp_w);
                                if isnan(value)
                                    nan_para = [nan_para,temp_w,','];
                                end
                                temp_w = num2str(value);
                            end
                            Csize{2*j-1} = temp_w;
                        end
                        pre_idx = idx_operator(j);
                    end
                    if numel(nan_para)==0
                        nan_para_list{bus_j} = 'pt';
                    else
                        nan_para_list{bus_j} = [' →',nan_para(1:end-1),'?'];
                    end
                    st2num_Csize = str2num(horzcat(Csize{:}));
                    if numel(st2num_Csize)==0
                        temp_size(bus_j) = nan;
                        nan_para_list{bus_j} = [' →',nan_para(1:end-1),'?'];
                    else
                        temp_size(bus_j) = st2num_Csize;
                    end
                end
                app.network_graph_data.Nsize(idx_temp,:) = temp_size(idx_temp);
            end
            temp  = temp|idx_temp;
        end
        app.network_graph_data.Ncolor(~temp,:) = {'k'};
        app.network_graph_data.Nshape(~temp,:) = {'o'};
        app.network_graph_data.Nsize(~temp,:) = 1;
        app.net_changed_color_switch = false;
   
    
        if app.graph_normalize_Button.Value
            max_Node_size = max(abs(app.network_graph_data.Nsize(~isnan(app.network_graph_data.Nsize))));
            xrange = diff(app.Panel_look_modelTree.XLim);
            yrange = diff(app.Panel_look_modelTree.YLim);
            normalize_size = sqrt(xrange*yrange/numel(app.net.a_bus))*15;
            app.network_graph_data.Nsize = app.network_graph_data.Nsize/max_Node_size*normalize_size;
        end

        app.Panel_net_component_label.Value =... 
            tools.varrayfun(@(b) {['Node',num2str(b,'%.2d'),' : ',num2str(app.network_graph_data.Nsize(b)),nan_para_list{b}]},...
            (1:numel(app.net.a_bus))');
        app.network_graph_data.Nsize(isnan(app.network_graph_data.Nsize))=10^(-5);

        if any(strcmp(app.network_graph_data.Ncolor,'pm'))
            pm_idx = strcmp(app.network_graph_data.Ncolor,'pm');
            sz = app.network_graph_data.Nsize(pm_idx);
            pm = cell(size(sz));
            pm(sz>=0) = {'#D95319'};
            pm(sz<0)  = {'#0072BD'};
            app.network_graph_data.Ncolor(pm_idx) = pm;
        end
        app.refresh_data_table_color;
    end

    con_set_table = app.graph_controller_switch_table.Data;
    con_table = supporters.for_user.func.look_controller(app.net);
    for i = 1:size(con_set_table,1)
        color = con_set_table{i,'color'};
        if con_set_table{i,{'idx_input'}}
            idx_temp_in = con_table{i,'idx_input'};
            app.network_graph_data.Ncolor(idx_temp_in{1},:) = color;
        elseif con_set_table{i,{'idx_observe'}}
            idx_temp_ob = con_table{i,'idx_observe'};
            app.network_graph_data.Ncolor(idx_temp_ob{1},:) = color;
        end
    end
    Ewid = app.network_graph_data.Ewidth;
    app.network_graph_data.Nsize(app.network_graph_data.Nsize==0)=10^(-5);
    app.network_graph_data.Nsize = abs(app.network_graph_data.Nsize);
    if app.Button_branch_switch.Value
        plot(app.Panel_look_modelTree,app.network_graph_data.g,...
                    'EdgeLabel'     ,app.network_graph_data.Eword,...
                    ...%'NodeFontSize'  ,app.network_graph_data.Nword_size,...
                    'LineWidth'     ,2*(0.01-min(Ewid)+Ewid),...
                    'EdgeColor'     ,'k',...
                    'Marker'        ,app.network_graph_data.Nshape,...
                    'NodeColor'     ,validatecolor(app.network_graph_data.Ncolor,'multiple'),...
                    'MarkerSize'    ,app.network_graph_data.Nsize);
    else
        plot(app.Panel_look_modelTree,app.network_graph_data.g,...
                    ...%'NodeFontSize'  ,app.network_graph_data.Eword,...
                    'LineWidth'     ,2*(0.01-min(Ewid)+Ewid),...
                    'EdgeColor'     ,'k',...
                    'Marker'        ,app.network_graph_data.Nshape,...
                    'NodeColor'     ,validatecolor(app.network_graph_data.Ncolor,'multiple'),...
                    'MarkerSize'    ,app.network_graph_data.Nsize);
    end
end

function value = func_get_para(app,bus_idx,para_name)
    value =  nan;
    if any(strcmp(app.power_flow_table.ColumnName,para_name))
        temp_idx = app.power_flow_table.Data{:,'bus_idx'}==bus_idx;
        value = app.power_flow_table.Data{temp_idx,para_name};
    elseif any(strcmp(app.equilibrium_table.ColumnName,para_name))
        temp_idx = app.equilibrium_table.Data{:,'bus_idx'}==bus_idx;
        value = app.equilibrium_table.Data{temp_idx,para_name};
    elseif any(strcmp(app.gen_parameter_table.ColumnName,para_name))
        temp_idx = app.gen_parameter_table.Data{:,'bus_idx'}==bus_idx;
        value = app.gen_parameter_table.Data{temp_idx,para_name};
    end
end
