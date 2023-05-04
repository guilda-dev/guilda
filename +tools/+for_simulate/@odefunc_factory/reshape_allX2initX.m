function [x_init,const_init] = reshape_allX2initX( obj, x, xcl, xcg, V, I, Vvirtual)

    idx = blkdiag(obj.cl_xmac_all{:});
    x0  = cell(obj.n_bus,1);
    for  i = obj.i_simulated_mac
        x0i = x(idx(:,i));
        if all(isnan(x0i))
            x0i = obj.power_network.a_bus{i}.component.x_equilibrium;
        end
        x0{i} = x0i(:);
    end
    x0  = vertcat(x0{:});

    idx = blkdiag(obj.cl_xcl_all{:});
    xcl0 = cell(obj.n_cl,1);
    for i = obj.i_simulated_cl
        xcl0i = xcl(idx(:,i));
        if all(isnan(xcl0i))
            xcl0i = obj.power_network.a_controller_local{i}.get_x0;
        end
        xcl0{i} = xcl0i(:);
    end
    xcl0= vertcat(xcl0{:});


    idx = blkdiag(obj.cl_xcg_all{:});
    xcg0 = cell(obj.n_cg,1);
    for i = obj.i_simulated_cg
        xcg0i = xcg(idx(:,i));
        if all(isnan(xcg0i))
            xcg0i = obj.power_network.a_controller_global{i}.get_x0;
        end
        xcg0{i} = xcg0i(:);
    end
    xcg0 = vertcat(xcg0{:});

    x_init = [x0; xcl0; xcg0];

    idx = [2*obj.i_simulated_bus-1; 2*obj.i_simulated_bus];
    V0 = V(idx);

    I0fault  = I(obj.l_Ibus_fault{1});

    V0unlink = cell(obj.n_bus,1);
    for i = 1:obj.n_bus
        if obj.l_Vvirtual_unlink(i)
            V0unlinki = Vvirtual(2*i+[-1,0]);
            if all(isnan(V0unlinki))
                V0unlinki = [1,0];
            end
            V0unlink{i} = V0unlinki(:);
        end
    end
    V0unlink = vertcat(V0unlink{:});

    const_init = [V0(:); I0fault(:); V0unlink];
        
end
