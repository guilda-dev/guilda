function [DAEvec, u] = get_dx_algebraic(obj, t, x, Vi, u, DAEvec)                

    if obj.isController
        a_LC = obj.a_LocalController{1};
        [DAEvec, u] = get_dx_algebraic(a_LC, t, x, Vi, u, DAEvec);    

        ueq = obj.cv_Uequilibrium;
        ueq(obj.str_u==a_LC.str_y) = u;

        u = ueq;
    end

    rv_x = obj.iv_odeX;
    rv_u = obj.iv_odeU;        
    
    x_con = x(rv_x);
    u_con = x(rv_u);        
    
    X = obj.fv_odeDiff(t, x_con, Vi, u_con);        
    
    DAEvec([rv_x;rv_u]) = DAEvec([rv_x;rv_u]) + [X; u_con - u];        
    u = obj.fv_odeY(t, x_con, Vi, u_con);    
end