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
        
            obj.JacobiAxx = @(t,x,V,I,u) getJacobiAxx(t, x, V, I, u, array, omega0);
            obj.JacobiBxv = @(t,x,V,I,u) getJacobiBxv(t, x, V, I, u, array, omega0);
            obj.JacobiBxi = @(t,x,V,I,u) getJacobiBxi(t, x, V, I, u, array, omega0);
            obj.JacobiBxu = @(t,x,V,I,u) getJacobiBxu(t, x, V, I, u, array, omega0);
        
            obj.JacobiCix = @(t,x,V,I,u) getJacobiCix(t, x, V, I, u, array, omega0);
            obj.JacobiDiv = @(t,x,V,I,u) getJacobiDiv(t, x, V, I, u, array, omega0);            
            obj.JacobiDii = @(t,x,V,I,u) getJacobiDii(t, x, V, I, u, array, omega0);
            obj.JacobiDiu = @(t,x,V,I,u) getJacobiDiu(t, x, V, I, u, array, omega0);
        
            obj.JacobiCyx = @(t,x,V,I,u) getJacobiCyx(t, x, V, I, u, array, omega0);
            obj.JacobiDyv = @(t,x,V,I,u) getJacobiDyv(t, x, V, I, u, array, omega0);
            obj.JacobiDyi = @(t,x,V,I,u) getJacobiDyi(t, x, V, I, u, array, omega0);
            obj.JacobiDyu = @(t,x,V,I,u) getJacobiDyu(t, x, V, I, u, array, omega0);
        
            obj.rm_odeMass = @(t,x,V,I,u) obj.fcn_Mass(t, x, V, I, u, array, omega0);            
            obj.fv_odeDiff = @(t,x,V,I,u) obj.fcn_dx(t, x, V, I, u, array, omega0);
            obj.fv_odeI    = @(t,x,V,I,u) obj.fcn_I(t, x, V, I, u, array, omega0);
            obj.fv_odeY    = @(t,x,V,I,u) obj.fcn_Y(t, x, V, I, u, array, omega0);
        end
    end
    methods        
        [cv_Xequilibrium, cv_Uequilibrium] = get_equilibrium(obj, c_V, c_I)        

        function PQ = getCompPQ(obj,x,V,u,para) %#ok
            
            V = V(1) * exp(1j*V(2));
                 
            Xdp  = para(4);
            Xdpp = para(5);     
            Xqp  = para(7);    
            Xqpp = para(8);
            Xls  = para(13);    
            
            % State
            delta = x(1);            
            Eq    = x(3);
            Ed    = x(4);
            psiq  = x(5);
            psid  = x(6);                        
            
            % dq-trans
            Vdq = exp(1j*delta) * conj(V);
            Vd  = imag(Vdq);
            Vq  = real(Vdq);
            
            % Current    
            Id = 1/Xdpp * (( (Xdpp-Xls)*Eq + (Xdp-Xdpp)*psid )/(Xdp-Xls) - Vq); 
            Iq = 1/Xqpp * (Vd - ( (Xqpp-Xls)*Ed - (Xqp-Xqpp)*psiq )/(Xqp-Xls));
            PQ = [Vd*Id + Vq*Iq;
                  Vq*Id - Vd*Iq];
                       
        end
    end        

    methods
        dx = fcn_dx(obj, t, x, V, I, u, para, omega0)
        I  = fcn_I(obj, t, x, V, I, u, para, omega0)
        y  = fcn_Y(obj, t, x, V, I, u, para, omega0)
        M  = fcn_Mass(obj, t, x, V, I, u, para, omega0)        
    end
       
end