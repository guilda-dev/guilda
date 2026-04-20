function [powerflow_bus,flag,output] = solve(obj, tab_PFset, cm_Y)

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
    rv_V0   = repmat([1;0],n_Bus,1);

    % solve
    [rv_Vsol,~,flag,output] = fsolve(@func, rv_V0, obj.optimoption);
    
    % sol -> Vbus -> Ibus -> Pbus,Qbus
    cv_Vbus = reshape(rv_Vsol,2,[]).' * [1;1j];
    cv_Ibus = cm_Y*cv_Vbus;
    cv_Sbus = cv_Vbus .* conj(cv_Ibus);
        
    % convert double->table
    str_bus = tab_PFset.Properties.RowNames;
    powerflow_bus = array2table(...
        [angle(cv_Vbus),abs(cv_Vbus),real(cv_Sbus),imag(cv_Sbus),cv_Vbus,cv_Ibus], ...
        "VariableNames",["Varg","V","P","Q","Vphasor","Iphasor"],"RowNames",str_bus);
    
    % Notify
    if flag<=0
        str_warnFlag = opt.WhenFailed;
        if str_warnFlag=="SYSTEM DEFAULT"
            struct_default = GUILDA.config("EnvFsolve");
            str_warnFlag = struct_default.WhenFailed;
        end
        switch str_warnFlag
        case "WARN" ; warning(output.message)
        case "ERROR"; error(output.message)
        case "DISP" ; disp(output.message)
        case "NONE" ; return
        end
    end

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

end

