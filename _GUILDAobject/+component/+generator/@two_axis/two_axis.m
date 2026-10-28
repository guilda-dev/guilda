classdef two_axis < component.generator.abstract
    properties (Constant)   
        key      = "gen-2axis";     
        sv_x    = ["delta";"omega";"Eq";"Ed"];        
        sv_u    = ["Pmech";"Vfield"];        
        sv_y    = ["omega"];        
        sv_para = ["M","D","Xd","Xd_p","Xq","Xq_p","Td_p","Tq_p"]        
    end        
       
    methods        
        [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, c_V, c_I, r_P, r_Q)        

        function PQ = getCompPQ(obj,x,V,u,para) %#ok

            c_V = [1,1j]*V;
       
            Xdp  = para(4);
            Xqp  = para(6);
           
            delta = x(1);
            Eq    = x(3);
            Ed    = x(4);
            
            Vdq = exp(1j*delta) * conj(c_V);
            Vd  = imag(Vdq);
            Vq  = real(Vdq);
            
            Id  = 1/Xdp * (Eq-Vq); 
            Iq  = 1/Xqp  *(Vd-Ed);          
                    
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