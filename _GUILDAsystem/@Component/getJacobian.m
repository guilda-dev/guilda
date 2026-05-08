function odeJacobian = getJacobian(obj, t, odeJacobian, iv_odeX)
    
    rv_x = obj.iv_odeX;
    rv_u = obj.iv_odeU;
    rv_v = obj.a_Bus.iv_odeX;

    rv_h = [rv_x; rv_u; a_bus{i}.iv_odeX];
    rv_v = [rv_x; a_bus{i}.iv_odeX];

    Axx = OBJ.JacobiAxx(t, xi, Vi, ui);
    Bxv = OBJ.JacobiBxv(t, xi, Vi, ui);
    Bxu = OBJ.JacobiBxu(t, xi, Vi, ui);                         

    Cyx = OBJ.JacobiCyx(t, xi, Vi, ui);
    Dyv = OBJ.JacobiDyv(t, xi, Vi, ui);
    Dyu = OBJ.JacobiDyu(t, xi, Vi, ui);    

    odeJacobian([rv_x; rv_v], [rv_x; rv_u; rv_v]) = odeJacobian([rv_x; rv_v], rv_h) + [ Axx,  Bxu,  Bxv; ...                                                                                   
                                                         -Cyx, -Dyu, -Dyv];

    Cix = OBJ.JacobiCix(t, xi, Vi, ui);
    Div = OBJ.JacobiDiv(t, xi, Vi, ui);
    Diu = OBJ.JacobiDiu(t, xi, Vi, ui);

end