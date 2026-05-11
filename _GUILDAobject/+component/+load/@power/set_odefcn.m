function set_odefcn(obj,~)
    tab_para = obj.tab_parameter;      
    array    = tab_para.dynamics{:,obj.str_para};

    obj.JacobiAxx = @(t,x,V,I,u) getJacobiAxx(t, x, V, I, u, array);
    obj.JacobiBxv = @(t,x,V,I,u) getJacobiBxv(t, x, V, I, u, array);
    obj.JacobiBxi = @(t,x,V,I,u) getJacobiBxi(t, x, V, I, u, array);
    obj.JacobiBxu = @(t,x,V,I,u) getJacobiBxu(t, x, V, I, u, array);

    obj.JacobiCix = @(t,x,V,I,u) getJacobiCix(t, x, V, I, u, array);
    obj.JacobiDiv = @(t,x,V,I,u) getJacobiDiv(t, x, V, I, u, array);
    obj.JacobiDii = @(t,x,V,I,u) getJacobiDii(t, x, V, I, u, array);
    obj.JacobiDiu = @(t,x,V,I,u) getJacobiDiu(t, x, V, I, u, array);

    obj.rm_odeMass = @(t,x,V,I,u) obj.fcn_Mass(t, x, V, I, u, []);
    obj.fv_odeDiff = @(t,x,V,I,u) obj.fcn_dx(t, x, V, I, u, []);
    obj.fv_odeI    = @(t,x,V,I,u) obj.fcn_I(t, x, V, I, u, []);
    obj.fv_odeY    = @(t,x,V,I,u) obj.fcn_Y(t, x, V, I, u, []);
end