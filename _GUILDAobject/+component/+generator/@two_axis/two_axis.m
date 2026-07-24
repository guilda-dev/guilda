classdef two_axis < component.generator.abstract
    properties (Constant)   
        key      = "gen-2axis";     
        str_x    = ["delta";"omega";"Eq";"Ed"];        
        str_u    = ["Pmech";"Vfield"];        
        str_y    = ["omega"];        
        str_para = ["M","D","Xd","Xd_p","Xq","Xq_p","Td_p","Tq_p"]        
    end        
       
    methods        
        [cv_Xequilibrium, cv_Uequilibrium] = get_equilibrium(obj, c_V, c_I)        

        function PQ = getCompPQ(obj,x,V,u,para) %#ok

            c_V = [1,1j]*V;
       
            Xdp  = param(4);
            Xqp  = param(6);
           
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

end