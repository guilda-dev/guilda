function dx = fx(t, x, net, stash)
    
    V = zeros(2,stash.num.bus);
    I = zeros(2,stash.num.bus); 

    nx = stash.num.bus+stash.num.cl+stash.num.cg;
    Vred = x(stash.logimat(:,nx+1));
    Ired = stash.Yred * Vred;
    I(:,stash.no_reduced_bus) = reshape(Ired,2,[]);
    V(:,stash.no_reduced_bus) = reshape(Vred,2,[]);
    I(:,stash.idx_V0const)    = reshape(x(stash.logimat(:,nx+2)), 2,[]);
    V(:,stash.idx_I0const)    = reshape(x(stash.logimat(:,nx+3)), 2,[]);
    

    U   = stash.utemp;
    X   = tools.arrayfun(@(i) x(stash.logimat(:,i)),(1:stash.num.bus));
    Xcl = tools.arrayfun(@(i) x(stash.logimat(:,i)),(1:stash.num.cl )+stash.num.bus);
    Xcg = tools.arrayfun(@(i) x(stash.logimat(:,i)),(1:stash.num.cg )+stash.num.bus+stash.num.cl);
    

    dxcg = cell(stash.num.cg ,1);
    for i = stash.simulated_cg
        c = net.a_controller_global{i};
        in = c.index_input;
        ob = c.index_observe;
        [dxcg{i},ug] = c.get_dx_u_func(t,Xcg{i},X(ob),num2cell(V(:,ob),1),num2cell(I(:,ob),1), []);
        for j = 1:numel(in)
            U{in(j)} = U{in(j)} + ug{j};
        end
    end
    Utemp = U;


    dxcl = cell(stash.num.cl ,1);
    for i = stash.simulated_cl
        c = net.a_controller_local{i};
        in = c.index_input;
        ob = c.index_observe;
        [dxcl{i},ul] = c.get_dx_u_func(t,Xcl{i},X(ob),num2cell(V(:,ob),1),num2cell(I(:,ob),1),Utemp(ob));
        for j = 1:numel(in)
            U{in(j)} = U{in(j)} + ul{j};
        end
    end

    for i = 1:numel(stash.ufunc)
        uf = stash.ufunc(i);
        uval = uf.ufunc(t);
        for j = 1:numel(uf.index)
            U{uf.index(j)} = U{uf.index(j)} + uval(uf.logimat(:,j),:);
        end
    end

    dx    = cell(stash.num.bus,1);
    const = cell(stash.num.bus,1);
    for i = stash.simulated_bus
        c = net.a_bus{i}.component;
        [dx{i}, const{i}] = c.get_dx_con_func( t, X{i}, V(:,i), I(:,i), c.u_equilibrium+U{i});
    end

    dx = [dx;dxcl;dxcg];
    con1 = const(stash.no_reduced_bus);
    con2 = const(stash.idx_I0const);
    
    
    dx   = [vertcat(dx{:})   ;...
            vertcat(con1{:}) ;...
            reshape(V(:,stash.idx_V0const),[],1) ;...
            vertcat(con2{:}) ];
end