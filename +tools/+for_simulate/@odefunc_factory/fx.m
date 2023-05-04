function dx = fx(obj, t, x, u)

    dx = zeros(obj.nX,1);
    U  = obj.zeros_u;
    
    dx(obj.l_Ibus_fault{3}) = x(obj.l_Ibus_fault{2});
     x(obj.l_Ibus_fault{2}) = 0;
    Vred = x(obj.l_Vall_simulated);
    Ired = obj.Ymat * Vred;
    V = zeros(2,obj.n_bus);
    I = zeros(2,obj.n_bus);
    V(:,obj.i_simulated_bus) = reshape(Vred,2,[]);
    I(:,obj.i_simulated_bus) = reshape(Ired,2,[]);
    I(:,obj.i_fault)         = reshape(x(obj.l_Ibus_fault{3}), 2,[]);

    var_mac = cell(obj.n_bus,1);
    var_con = cell(obj.n_bus,1);

    if  ~isempty(obj.i_simulated_cl) || ~isempty(obj.i_simulated_cg)
        x_mac = tools.arrayfun(@(i) x(obj.l_xmac_simulated(:,i)), 1:obj.n_bus);

        for i = obj.i_simulated_cg
           c = obj.power_network.a_controller_global{i};
           ivar = {x(obj.l_xcg_simulated(:,i)), x_mac(c.index_observe), num2cell(V(:, c.index_observe),1), num2cell(I(:, c.index_observe),1), []};
           [dx(obj.l_xcg_simulated(:,i)), ug] = c.get_dx_u_func(t, ivar{:});
           var_con{obj.n_cl+i} = ivar;
           for i_input = c.index_input(:)'
               U{i_input} = U{i_input} + ug{i_input};
           end
        end
        U_global = U;

        for i = obj.i_simulated_cl
           c = obj.power_network.a_controller_local{i};
           ivar = {x(obj.l_xcl_simulated(:,i)), x_mac(c.index_observe), num2cell(V(:, c.index_observe),1), num2cell(I(:, c.index_observe),1), U_global(c.index_observe)};
           [dx(obj.l_xcl_simulated(:,i)), ul] = c.get_dx_u_func(t, ivar{:});
           var_con{i} = ivar;
           for i_input = c.index_input(:)'
               U{i_input} = U{i_input} + ul{i_input};
           end
        end
    end

    for i = 1:numel(obj.i_input)
        idx = obj.i_input(i);
        U{idx} = U{idx} + u(obj.l_input(:,i));
    end

    for i = obj.i_simulated_mac(:)'
        c = obj.power_network.a_bus{i}.component;
        ivar = {x(obj.l_xmac_simulated(:,i)),V(:,i),I(:,i),U{i}};
        [dx(obj.l_xmac_simulated(:,i)),  dx(obj.l_constraint(:,i))] = c.get_dx_con_func(t, ivar{:});
        var_mac{i} = ivar;
    end
    
    if ~isempty(obj.StateHolder)
        obj.StateHolder.set_vargin_mac(var_mac)
        obj.StateHolder.set_vargin_controller(var_con)
        obj.StateHolder.set_vargin_branch(Vred);
    end
end