function idx = look_state_list(net)

    idx ={};
    for busi = 1:numel(net.a_bus)
        idx = unique([idx,net.a_bus{busi}.component.get_state_name]);
    end
    [~,sort_idx] = sort(upper(idx));
    idx = idx(sort_idx);

end