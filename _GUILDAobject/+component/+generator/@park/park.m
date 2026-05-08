classdef park < component.generator.abstract

    properties (Constant)   
        key      = "gen-park";     
        str_x    = ["delta";"omega";"Eq";"Ed";"psiq";"psid"];        
        str_u    = ["Pmech";"Vfield"];        
        str_y    = ["omega"];        
        str_para = ["M","D","Xd","Xd_p","Xd_pp","Xq","Xq_p","Xq_pp","Td_p","Td_pp","Tq_p","Tq_pp","X_ls"]        
    end        
    
    methods        
        function set_odefcn(obj, omega0)                                
            tab_para = obj.tab_parameter;      
            array    = tab_para.dynamics{:,obj.str_para};

            obj.JacobiAxx = @(t, x, V, u) getJacobiAxx(t, x, V, u, array, omega0);
            obj.JacobiBxv = @(t, x, V, u) getJacobiBxv(t, x, V, u, array, omega0);
            obj.JacobiBxu = @(t, x, V, u) getJacobiBxu(t, x, V, u, array, omega0);

            obj.JacobiCix = @(t, x, V, u) getJacobiCix(t, x, V, u, array, omega0);
            obj.JacobiDiv = @(t, x, V, u) getJacobiDiv(t, x, V, u, array, omega0);            
            obj.JacobiDiu = @(t, x, V, u) getJacobiDiu(t, x, V, u, array, omega0);

            obj.JacobiCyx = @(t, x, V, u) getJacobiCyx(t, x, V, u, array, omega0);
            obj.JacobiDyv = @(t, x, V, u) getJacobiDyv(t, x, V, u, array, omega0);
            obj.JacobiDyu = @(t, x, V, u) getJacobiDyu(t, x, V, u, array, omega0);                        

            obj.rm_odeMass = @(t, x, V, u) obj.fcn_Mass(t, x, V, u, array, omega0);            
            obj.fv_odeDiff = @(t, x, V, u) obj.fcn_dx(t, x, V, u, array, omega0);
            obj.fv_odeI    = @(t, x, V, u) obj.fcn_I(t, x, V, u, array, omega0);
            obj.fv_odeY    = @(t, x, V, u) obj.fcn_Y(t, x, V, u, array, omega0);
        end
    end
    methods        
        [cv_Xequilibrium, cv_Uequilibrium] = get_equilibrium(obj, c_V, c_I)        
    end        

    methods
        dx = fcn_dx(obj, t, x, V, u, para, omega0)
        I  = fcn_I(obj, t, x, V, u, para, omega0)
        y  = fcn_Y(obj, t, x, V, u, para, omega0)
        M  = fcn_Mass(obj, t, x, V, u, para, omega0)        
    end
       
end