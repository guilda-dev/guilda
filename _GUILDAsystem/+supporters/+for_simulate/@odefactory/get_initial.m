function [x0,index] = get_initial(obj)

    net = obj.network; 
    x0  = nan(numel(obj.logimat.V),1);

    index = false(numel(obj.logimat.V),1);

    for i = 1:numel(obj.simulated_bus)
        idx  = obj.simulated_bus(i);
        temp = obj.initial.x{idx};
        if any(isnan(temp))
            x0(obj.logimat.x(:,i)) = net.a_bus{idx}.component.x_equilibrium;
            index(obj.logimat.x(:,i)) = true;
        else
            x0(obj.logimat.x(:,i)) = temp;
        end
    end

    for i = 1:numel(obj.simulated_cl)
        idx = obj.simulated_cl(i);
        temp = obj.initial.xcl{idx};
        if any(isnan(temp))
            x0(obj.logimat.xcl(:,i)) = net.a_controller_local{i}.get_x0;
        else
            x0(obj.logimat.xcl(:,i)) = temp;
        end
    end

    for i = 1:numel(obj.simulated_cg)
        idx = obj.simulated_cg(i);
        temp = obj.initial.xcg{idx};
        if any(isnan(temp))
            x0(obj.logimat.xcg(:,i)) = net.a_controller_global{i}.get_x0;
        else
            x0(obj.logimat.xcg(:,i)) = temp;
        end
    end

    V = horzcat(obj.initial.V{obj.noreduced_bus});
    x0(obj.logimat.V) = reshape(V,[],1);

    if ~isempty(obj.V0const_bus)
        V0 = horzcat(obj.initial.V0const{obj.V0const_bus});
        idx = any(isnan(V0),1);
        V0(1,idx) = 1; 
        V0(2,idx) = 0; 
        x0(obj.logimat.V0const)    = reshape(V0,[],1);
        index(obj.logimat.V0const) = reshape([idx;idx],[],1);
    end

    if ~isempty(obj.I0const_bus)
        I0 = horzcat(obj.initial.I0const{obj.I0const_bus});
        idx = any(isnan(I0),1);
        I0(1,idx) = 1; 
        I0(2,idx) = 0; 
        x0(obj.logimat.I0const) = reshape(I0,[],1);
        index(obj.logimat.I0const) = reshape([idx;idx],[],1);
    end
end