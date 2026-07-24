classdef park < component.generator.abstract

    properties (Constant)   
        key      = "gen-park";     
        sv_x    = ["delta";"omega";"Eq";"Ed";"psiq";"psid"];        
        sv_u    = ["Pmech";"Vfield"];        
        sv_y    = ["omega"];        
        sv_para = ["M","D","Xd","Xd_p","Xd_pp","Xq","Xq_p","Xq_pp","Td_p","Td_pp","Tq_p","Tq_pp","X_ls"]        
    end        
        
    methods        
        [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, c_V, c_I)        

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
       
    methods (Static)        
        [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0);
        [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0);
        [Cix,Div,Dii,Diu] = Jacobi_I(t,x,V,I,u,param,omega0);
    end
end