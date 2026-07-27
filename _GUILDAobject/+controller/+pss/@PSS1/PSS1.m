classdef (Sealed = true) PSS1 < controller.pss.abstract

    methods
        function obj = PSS1(tag, param)
            arguments            
                tag            (1,1) string
                param.kpss     (1,1) double = 5
                param.tWS      (1,1) double = 10
                param.tn1      (1,1) double = 0.05
                param.td1      (1,1) double = 0.02
                param.tn2      (1,1) double = 3.00
                param.td2      (1,1) double = 5.40
                param.Vpss_min (1,1) double = -Inf
                param.Vpss_max (1,1) double = Inf
                
            end            
            obj@controller.pss.abstract(tag)                                    
            
            obj.para_dynamics.add_entry(   "kpss", param.kpss    , "double", ...
                                            "tWS", param.tWS     , "double", ...
                                            "tn1", param.tn1     , "double", ...
                                            "td1", param.td1     , "double", ...
                                            "tn2", param.tn2     , "double", ...
                                            "td2", param.td2     , "double", ...
                                       "Vpss_max", param.Vpss_max, "double", ...
                                       "Vpss_min", param.Vpss_min, "double");          

            obj.key      = "pss";
            obj.sv_x    = ["xiWS"; "xi1"; "xi2"];
            obj.sv_u    = "omega";   
            obj.sv_y    = "Vpss";
            obj.sv_para = ["kpss"; "tWS"; "tn1"; "td1"; "tn2"; "td2"; "Vpss_min"; "Vpss_max"];

            obj.set_odefcn(60);

        end        
        
        function get_equilibrium(obj, V, u) %#ok
            obj.rv_Xequilibrium = zeros(3,1);
            obj.rv_Uequilibrium = 0;
        end
    end

    methods (Static)
        dx = fcn_dx(obj, t, x, V, I, u, para, omega0)
        y  = fcn_y(obj, t, x, V, I, u, para, omega0)
        M  = fcn_Mass(obj, t, x, V, I, u, para, omega0)

        [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0)
        [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0)
    end    
end
