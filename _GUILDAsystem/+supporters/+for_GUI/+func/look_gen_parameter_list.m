function list = look_gen_parameter_list(net)

    pidx = find(tools.vcellfun(@(b) isprop(b.component,'parameter'),net.a_bus));
    list ={};
    for busi = pidx.'
        list = unique([list,net.a_bus{busi}.component.parameter.Properties.VariableNames]);
    end
    [~,sort_idx] = sort(upper(list));
    list = list(sort_idx);

end