function set_odefcn(obj,~)
    tab_para = obj.tab_parameter;      
    array    = tab_para.dynamics{:,obj.str_para};

    obj.JacobiAxx = @(t, x, V, u) getJacobiAxx(t, x, V, u, array);
    obj.JacobiBxv = @(t, x, V, u) getJacobiBxv(t, x, V, u, array);
    obj.JacobiBxu = @(t, x, V, u) getJacobiBxu(t, x, V, u, array);
    obj.JacobiCix = @(t, x, V, u) getJacobiCix(t, x, V, u, array);
    obj.JacobiDiv = @(t, x, V, u) getJacobiDiv(t, x, V, u, array);
    obj.JacobiDiu = @(t, x, V, u) getJacobiDiu(t, x, V, u, array);

    obj.rm_odeMass = @(t, x, V, u) obj.fcn_Mass(t, x, V, u, []);
    obj.fv_odeDiff = @(t, x, V, u) obj.fcn_dx(t, x, V, u, []);
    obj.fv_odeI    = @(t, x, V, u) obj.fcn_I(t, x, V, u, []);
    obj.fv_odeY    = @(t, x, V, u) obj.fcn_Y(t, x, V, u, []);
end