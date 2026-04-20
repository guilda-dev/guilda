function set_equilibrium(obj, c_V, c_I, r_P, r_Q, opt)
    arguments
        obj 
        c_V 
        c_I 
        r_P = real( c_V*conj(c_I) );
        r_Q = imag( c_V*conj(c_I) ); 
        opt.QdistributionRule (1,1) string {mustBeMember(opt.QdistributionRule,["baseMVA","Qmax"])} = "baseMVA";
    end
    
    obj.c_Vequilibrium = c_V;
    obj.c_Iequilibrium = c_I;
    obj.rv_odeX0 = [real(c_V); imag(c_V)];

    a_Comp     = obj.a_Component;
    n_Comp     = numel(a_Comp);
    tab_PQcomp = tools.vcellfun(@(c) c.para_powerflow.tab_parameter, a_Comp);

    % distrubute active power(P)
    if obj.l_isSlack
        if n_Comp == 1
            tab_PQcomp{1,"P"} = r_P;
        else
            tab_PQcomp{1,"P"} = r_P - sum(tab_PQcomp{2:end,"P"});
        end
    end

    % distribute reactive power(Q)
    lv_Qnan  = isnan(tab_PQcomp.Q);
    r_Qrest  = r_Q - sum(tab_PQcomp{~lv_Qnan,"Q"});
    if any(lv_Qnan)
        if sum(lv_Qnan) == 1
            tab_PQcomp{lv_Qnan,"Q"} = r_Qrest;
        else 
            tab_Ocomp = tools.vcellfun(@(c) c.para_operation.tab_parameter, a_Comp);
                rv_Qmin = tab_Ocomp{lv_Qnan,"Qmin"};
                rv_Qmax = tab_Ocomp{lv_Qnan,"Qmax"};
            if opt.QdistributionRule=="Qmax" && ~any( isinf([rv_Qmin,rv_Qmax]), "all")
                r_Qminall = sum(rv_Qmin);
                r_Qmaxall = sum(rv_Qmax); 
                rv_Qrate  = (rv_Qmax-rv_Qmin)/(r_Qmaxall-r_Qminall);
                tab_PQcomp{lv_Qnan,"Q"} = rv_Qmin + rv_Qrate * (r_Qrest-r_Qminall);
            else
                rv_Qrate = tab_Ocomp{lv_Qnan,"baseMVA"};
                tab_PQcomp{lv_Qnan,"Q"} = r_Qrest * rv_Qrate/sum(rv_Qrate);
            end
        end
    end

    % @Component set_equilibrium
    for i = 1:n_Comp
        rr_PQi = tab_PQcomp{i,["P","Q"]};
        r_Pi   = rr_PQi(1);
        r_Qi   = rr_PQi(2);
        c_Ii   = conj( rr_PQi*[1;1j] / c_V );
        a_Comp{i}.set_equilibrium(c_V,c_Ii,r_Pi,r_Qi);
    end
end
