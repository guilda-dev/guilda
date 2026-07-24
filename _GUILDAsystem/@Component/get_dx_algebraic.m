function DAEvec = get_dx_algebraic(obj, t, x, Vi, Ii, u, DAEvec) 

    rv_x = obj.iv_odeX;
    rv_u = obj.iv_odeU;

    rv_v = obj.a_Bus.iv_odeX;

    x_comp = x(rv_x);
    u_comp = x(rv_u);    
    
    y_comp = obj.f_Y(t,x_comp,Vi,Ii,u_comp);
    y_name = obj.sv_y;

    if obj.l_hasController
        a_LC = obj.a_LocalController{1};
        [DAEvec, y_avr, y_name] = get_dx_algebraic(a_LC, t, x, Vi, Ii, y_comp, y_name, DAEvec);
        u(obj.sv_u==y_name) = y_avr;
    end
    
    X = obj.f_dx(t,x_comp,Vi,Ii,u_comp);
    I = obj.l_isConnect * obj.f_I(t,x_comp,Vi,Ii,u_comp);       

    DAEvec([rv_x; rv_u; rv_v]) = DAEvec([rv_x; rv_u; rv_v]) + [X; u_comp-u; -[real(I); imag(I)]];        

end