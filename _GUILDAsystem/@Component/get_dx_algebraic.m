function DAEvec = get_dx_algebraic(obj, t, x, Vi, Ii, u, DAEvec) 

    rv_x = obj.iv_odeX;
    rv_u = obj.iv_odeU;

    rv_v = obj.a_Bus.iv_odeX;

    x_comp = x(rv_x);
    u_comp = x(rv_u);    
    
    y_comp = obj.fv_odeY(t,x_comp,Vi,Ii,u_comp);

    if obj.isController
        a_LC = obj.a_LocalController{1};
        [DAEvec, y_avr] = get_dx_algebraic(a_LC, t, x, Vi, Ii, y_comp, DAEvec);
        u(obj.str_u==a_LC.str_y) = y_avr;
    end
    
    X = obj.fv_odeDiff(t,x_comp,Vi,Ii,u_comp);
    I = obj.isConnect * obj.fv_odeI(t,x_comp,Vi,Ii,u_comp);       

    DAEvec([rv_x; rv_u; rv_v]) = DAEvec([rv_x; rv_u; rv_v]) + [X; u_comp-u; -[real(I); imag(I)]];        

end