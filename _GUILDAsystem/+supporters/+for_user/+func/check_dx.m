function [judge,dx] = check_dx(net)
    
    check_dx = @(b) net.bus{b}.component.get_dx(net.bus{b}.component.x_st,[net.V_ss(b*2-1);net.V_ss(b*2)],[0;0]);
    [is_gen,~,~,~]=func.search_idx_component(net);
    idx_gen = find(is_gen');
    dx = [];
    for i = idx_gen
        dx = [dx,check_dx(i)];
    end
    if any(dx>10^(-9))
        judge = false;
        disp('平衡点が正しくセットされていません．')
    else
        judge = true;
    end
end

