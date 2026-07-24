classdef one_axis < component.generator.abstract
    properties (Constant)        
        key      = "gen-1axis";
        sv_x    = ["delta";"omega";"Eq"];        
        sv_u    = ["Pmech";"Vfield"];        
        sv_y    = ["omega"];        
        sv_para = ["M";"D";"Xd";"Xq";"Xd_p";"Td_p"]
    end        

    methods        
        [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, c_V, c_I, r_P, r_Q)       
    end        
    methods
        dx = fcn_dx(obj,t,x,V,I,u,para,omega0)
        I  = fcn_I(obj,t,x,V,I,u,para,omega0)
        y  = fcn_Y(obj,t,x,V,I,u,para,omega0)
        M  = fcn_Mass(obj,t,x,V,I,u,para,omega0)
    end
    methods (Static)        
        [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0);
        [Cyx,Dyv,Dyi,Dyu] = Jacobi_y(t,x,V,I,u,param,omega0);
        [Cix,Div,Dii,Diu] = Jacobi_I(t,x,V,I,u,param,omega0);
    end

    methods
        function PQ = getCompPQ(obj,x,V,u,para) %#ok

            V = V(1) * exp(1j*V(2));
            
            Xq = para(4);
            Xdp  = para(5);     

            % State
            delta = x(1);            
            Eq    = x(3);                            

            % dq-trans
            Vdq = exp(1j*delta) * conj(V);
            Vd  = imag(Vdq);
            Vq  = real(Vdq);

            % Current    
            Id = Vd/Xq;
            Iq = (Eq - Vq)/Xdp;
            PQ = [Vd*Id + Vq*Iq;
                  Vq*Id - Vd*Iq];

        end
    end
end