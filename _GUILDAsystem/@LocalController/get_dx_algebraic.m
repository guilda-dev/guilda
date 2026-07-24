function [DAEvec, u, y_name] = get_dx_algebraic(obj, t, x, Vi, Ii, u, y_name, DAEvec) 

    rv_U = obj.rv_Uequilibrium;

    lv_U2Y = ismember(obj.sv_u,y_name);
    lv_Y2U = ismember(y_name,obj.sv_u);

    rv_U(lv_U2Y) = u(lv_Y2U);

    if obj.l_hasController
        a_LC = obj.a_LocalController{1};
        
        lv_Y2U = ismember(y_name,a_LC.sv_u);        

        u_LC = u(lv_Y2U);

        [DAEvec, y_LC, y_name] = get_dx_algebraic(a_LC, t, x, Vi, Ii, u_LC, y_name, DAEvec);    
        
        lv_U2Y = ismember(obj.sv_u,y_name);
        rv_U(lv_U2Y) = y_LC;        
    end

    rv_x = obj.iv_odeX;
    rv_u = obj.iv_odeU;        
    
    x_con = x(rv_x);
    u_con = x(rv_u);        
    
    X = obj.f_dx(t, x_con, Vi, Ii, u_con);        
    
    DAEvec([rv_x;rv_u]) = DAEvec([rv_x;rv_u]) + [X; u_con - rv_U];        
    u = obj.f_Y(t, x_con, Vi, Ii, u_con);  
    y_name = obj.sv_y;
    
end

function rv_aEb = ismember(a,b)
    rv_aEb = cast(sum(a==b',2),'logical');
end