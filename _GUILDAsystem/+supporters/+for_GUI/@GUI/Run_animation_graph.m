function Run_animation_graph(app)
fps = 10;
if app.out_changed

    Ncolor = app.animation_Node_color_List.Value;
    Nsize  = app.animation_Node_size_List.Value;

    paraidx = tools.vcellfun(@(b) isprop(b.component,'parameter'),app.net.a_bus);
    para_Variable = tools.harrayfun(@(b) app.net.a_bus{b}.component.parameter.Properties.VariableNames,find(paraidx),'UniformOutput',false);
    para_Variable = unique(para_Variable);
    if any(strcmp(para_Variable,Ncolor))
        app.animation_Node_color_st.SelectedObject = app.color_not_st;
    end
    if any(strcmp(para_Variable,Nsize))
        app.animation_Node_size_st.SelectedObject = app.size_not_st;
    end


    if app.color_st.Value
        Nc_st = true;
    else
        Nc_st = false;
    end
    if app.size_st.Value
        Ns_st = true;
    else
        Ns_st = false;
    end

    temp_position = app.GUILDA_GUIsimulator.Position;
    temp_position([1,2]) = temp_position([1,2])+5;
    temp_position(3) = temp_position(3)-10;
    temp_position(4) = temp_position(4)*0.85;

    app.animation_graph_data = ...
        simulation.out_fuctory.animation_graph_plot(app.net,app.out,...
                                    'fps'       ,fps,...
                                    'Ncolor'    ,Ncolor,...
                                    'Nc_st'     ,Nc_st,...
                                    'Nsize'     ,Nsize,...
                                    'Ns_st'     ,Ns_st,...
                                    'Visible'   ,true,...             
                                    'graph_data',app.network_graph_data,...
                                    'position'  ,temp_position);
    app.out_changed = false;

else
    [h, w, ~] = size(app.animation_graph_data(1).cdata);
    hf = figure; 
    Position = app.GUILDA_GUIsimulator.Position;
    set(hf, 'position', [Position(1) Position(2) w h]);
    axis off
    movie(hf,app.animation_graph_data,1,fps)
end

end