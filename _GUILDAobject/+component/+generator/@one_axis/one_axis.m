classdef one_axis < component.generator.abstract
    properties (Constant)        
        key      = "gen-1axis";
        str_x    = ["delta";"omega";"Eq"];        
        str_u    = ["Pmech";"Vfield"];        
        str_y    = ["omega";"Efd";"Vabs"];        
        str_para = ["M";"D";"Xd";"Xq";"Xd_p";"Td_p"]
    end        

    methods
        function set_odefcn(obj, omega0)                                
            tab_para = obj.tab_parameter;      
            array    = tab_para.dynamics{:,obj.str_para};

            obj.JacobiA = @(t, x, V, u) getJacobiA(t, x, V, u, array, omega0);
            obj.JacobiB = @(t, x, V, u) getJacobiB(t, x, V, u, array, omega0);
            obj.JacobiC = @(t, x, V, u) getJacobiC(t, x, V, u, array, omega0);
            obj.JacobiD = @(t, x, V, u) getJacobiD(t, x, V, u, array, omega0);

            obj.rm_odeMass = @(t, x, V, u) obj.fcn_Mass(t, x, V, u, array, omega0);            
            obj.fv_odeDiff = @(t, x, V, u) obj.fcn_dx(t, x, V, u, array, omega0);
            obj.fv_odeI    = @(t, x, V, u) obj.fcn_I(t, x, V, u, array, omega0);
        end
    end

    methods        
        [cv_Xequilibrium, cv_Uequilibrium] = get_equilibrium(obj, c_V, c_I, r_P, r_Q)       
    end        
    methods
        dx = fcn_dx(obj, t, x, V, u, para, omega0)
        I  = fcn_I(obj, t, x, V, u, para, omega0)
        M  = fcn_Mass(obj, t, x, V, u, para, omega0)
    end
end