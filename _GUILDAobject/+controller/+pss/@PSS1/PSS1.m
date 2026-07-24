classdef (Sealed = true) PSS1 < controller.pss.base

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
            obj@controller.pss.base(tag)                                    
            
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

        end        
        function set_odefcn(obj, omega0)
            params = obj.tab_parameter.dynamics{:,obj.sv_para};
            obj.f_dx = @(t,x,V,I,u) obj.fcn_dx(t, x, V, I, u, params, omega0);            
            obj.f_Mass = @(t,x,V,I,u) obj.fcn_Mass(t, x, V, I, u, params, omega0);
            obj.f_Y    = @(t,x,V,I,u) obj.fcn_y(t, x, V, I, u, params, omega0);

            obj.JacobiAxx = @(t,x,V,I,u) getJacobiAxx(t, x, V, I, u, params, omega0);
            obj.JacobiBxv = @(t,x,V,I,u) getJacobiBxv(t, x, V, I, u, params, omega0);
            obj.JacobiBxi = @(t,x,V,I,u) getJacobiBxi(t, x, V, I, u, params, omega0);
            obj.JacobiBxu = @(t,x,V,I,u) getJacobiBxu(t, x, V, I, u, params, omega0);

            obj.JacobiCyx = @(t,x,V,I,u) getJacobiCyx(t, x, V, I, u, params, omega0);
            obj.JacobiDyv = @(t,x,V,I,u) getJacobiDyv(t, x, V, I, u, params, omega0);            
            obj.JacobiDyi = @(t,x,V,I,u) getJacobiDyi(t, x, V, I, u, params, omega0);
            obj.JacobiDyu = @(t,x,V,I,u) getJacobiDyu(t, x, V, I, u, params, omega0);

        end
        function get_equilibrium(obj, V, u) %#ok
            obj.rv_Xequilibrium = zeros(3,1);
            obj.rv_Uequilibrium = 0;
        end
    end

    methods
        dx = fcn_dx(obj, t, x, V, I, u, para, omega0)
        y  = fcn_y(obj, t, x, V, I, u, para, omega0)
        M  = fcn_Mass(obj, t, x, V, I, u, para, omega0)
    end
end
