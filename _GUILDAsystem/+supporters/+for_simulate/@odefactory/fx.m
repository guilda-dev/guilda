function dx = fx(obj, t, x)
    
    net = obj.network;
    [X,Xcl,Xcg,V,I] = obj.organize_Xode(x);

    dxcg = cell(numel(Xcg),1);
    U = obj.all_Uzeros;
    for i = obj.simulated_cg
        c = net.a_controller_global{i};
        in = c.index_input;
        ob = c.index_observe;
        [dxcg{i},ug] = c.get_dx_u_func( t, Xcg{i}, X(ob), num2cell(V(:,ob),1), num2cell(I(:,ob),1), []);
        for j = 1:numel(in)
            U{in(j)} = U{in(j)} + ug{j};
        end
    end
    Utemp = U;


    dxcl = cell(numel(Xcl),1);
    for i = obj.simulated_cl
        c = net.a_controller_local{i};
        in = c.index_input;
        ob = c.index_observe;
        [dxcl{i},ul] = c.get_dx_u_func( t, Xcl{i}, X(ob), num2cell(V(:,ob),1), num2cell(I(:,ob),1), Utemp(ob));
        for j = 1:numel(in)
            U{in(j)} = U{in(j)} + ul{j};
        end
    end


    for i = 1:numel(obj.ufunc)
        ui = obj.ufunc(i);
        uval = ui.function(t);
        for j = 1:numel(ui.index)
            U{ui.index(j)} = U{ui.index(j)} + uval(ui.logimat(:,j));
        end
    end

    dxcon = cell(numel(X),1);
    for i = obj.simulated_bus
        c = net.a_bus{i}.component;
        [dx, con] = c.get_dx_con_func( t, X{i}, V(:,i), I(:,i), c.u_equilibrium+U{i});
        dxcon{i} = [dx;con];
    end

    dx = [  vertcat(dxcon{:}) ;
            vertcat( dxcl{:}) ;
            vertcat( dxcg{:}) ];
    
end