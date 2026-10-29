function [cv_Vbus,flag,output,cm_Vhistory,rv_step] = solve_algebraic(obj, cm_Y, tab_PFset, s_options)
% Solves the power equations with fsolve. cm_Vhistory holds the bus voltages at each
% iteration (n_bus x n_step), rv_step the iteration numbers.

    % Collect Info
    rm_Y  = sparse(tools.complex2matrix(cm_Y));
    n_Bus = size(tab_PFset,1);

    % Build Power Equation
    fcn_PowerEq = cell(n_Bus,1);
    for i_bus = 1:n_Bus
        switch tab_PFset{i_bus,"Type"}
            case "PV"
                star = tab_PFset{i_bus,["P","V"]}.';
                fcn_PowerEq{i_bus}  = @(v,i) PFconst_PV(v,i,star) ;
            case "PQ"
                star = tab_PFset{i_bus,["P","Q"]}.';
                fcn_PowerEq{i_bus}  = @(v,i) PFconst_PQ(v,i,star) ;
            case "slack"
                star = tab_PFset{i_bus,["Varg","V"]}.';
                fcn_PowerEq{i_bus}  = @(v,i) PFconst_slack(v,i,star) ;
        end
    end

    % initial condition
    V0 = tab_PFset.V0;
    T0 = tab_PFset.Varg0;
    
    rv_V0 = reshape([V0.*cos(T0), V0.*sin(T0)].', [], 1);

    % optimoptions (the iterates are recorded by the nested function record)
    opt = optimoptions(obj.optimoption(s_options), "OutputFcn", @record);
    rm_hist = nan(2*n_Bus, 0);
    n_iter  = 0;

    % solve
    [rv_Vsol,~,flag,output] = fsolve(@func, rv_V0, opt);

    cm_Vhistory = rm_hist(1:2:end,1:n_iter) + 1j*rm_hist(2:2:end,1:n_iter);
    rv_step     = 0:n_iter-1;

    % sol -> Vbus -> Ibus -> Pbus,Qbus
    cv_Vbus = reshape(rv_Vsol,2,[]).' * [1;1j];

    % function
    function [con,jacobi] = func(rv_V)
        con  = zeros(2*n_Bus,1);
        jacobi_V = zeros(2*n_Bus,2*n_Bus);
        jacobi_I = zeros(2*n_Bus,2*n_Bus);
        rv_I = rm_Y*rv_V;
        rm_V = reshape(rv_V,2,[]);
        rm_I = reshape(rv_I,2,[]);
        for i = 1:n_Bus
            iv_con = 2*i+[-1,0];
            rv_Vi  = rm_V(:,i);
            rv_Ii  = rm_I(:,i);
            [con(iv_con),...
             jacobi_V(iv_con,iv_con),...
             jacobi_I(iv_con,iv_con)] = fcn_PowerEq{i}(rv_Vi,rv_Ii);    
        end
        jacobi = sparse( jacobi_V+jacobi_I*rm_Y );
    end

    function stop = record(x, ~, state)
        stop = false;
        if state == "iter"
            n_iter = n_iter + 1;
            if n_iter > size(rm_hist,2)
                rm_hist = [rm_hist, nan(numel(x),1000)];
            end
            rm_hist(:,n_iter) = x;
        end
    end

end
