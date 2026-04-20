function set_odefcn(obj,~)
    tab_para = obj.tab_parameter;      
    array    = tab_para.dynamics{:,obj.str_para};

    obj.JacobiA = @(t, x, V, u) getJacobiA(t, x, V, u, array);
    obj.JacobiB = @(t, x, V, u) getJacobiB(t, x, V, u, array);
    obj.JacobiC = @(t, x, V, u) getJacobiC(t, x, V, u, array);
    obj.JacobiD = @(t, x, V, u) getJacobiD(t, x, V, u, array);         

    obj.rm_odeMass = @(t, x, V, u) obj.fcn_Mass(t, x, V, u, []);
    obj.fv_odeDiff = @(t, x, V, u) obj.fcn_dx(t, x, V, u, []);
    obj.fv_odeI    = @(t, x, V, u) obj.fcn_I(t, x, V, u, []);
end