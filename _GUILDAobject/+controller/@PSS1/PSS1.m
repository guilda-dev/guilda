classdef (Sealed = true) PSS1 < LocalController
    properties (Constant, Hidden=true)
        key      = "pss"
        str_x    = ["xiWS"; "xi1"; "xi2"];
        str_u    = ["omega"];   
        str_y    = ["Vpss"];
        str_para = ["kpss"; "tWS"; "tn1"; "td1"; "tn2"; "td2"; "Vpss_min"; "Vpss_max"];
    end    
    methods
        function obj = PSS1(tag, param)
            arguments            
                tag            (1,1) string
                param.kpss     (1,1) double = 20
                param.tWS      (1,1) double = 10
                param.tn1      (1,1) double = 0.05
                param.td1      (1,1) double = 0.02
                param.tn2      (1,1) double = 3.00
                param.td2      (1,1) double = 5.40
                param.Vpss_min (1,1) double = -Inf
                param.Vpss_max (1,1) double = Inf
                
            end            
            obj@LocalController("CP"+tag)                                    
            
            obj.para_dynamics.add_entry(   "kpss", param.kpss    , "double", ...
                                            "tWS", param.tWS     , "double", ...
                                            "tn1", param.tn1     , "double", ...
                                            "td1", param.td1     , "double", ...
                                            "tn2", param.tn2     , "double", ...
                                            "td2", param.td2     , "double", ...
                                       "Vpss_max", param.Vpss_max, "double", ...
                                       "Vpss_min", param.Vpss_min, "double");                        

        end        
        function set_odefcn(obj, omega0)
            params = obj.tab_parameter.dynamics{:,obj.str_para};
            obj.fv_odeDiff = @(t, x, V, u) obj.fcn_dx(t, x, V, u, params, omega0);
            obj.fv_odeConY = @(t, x, V, u) obj.fcn_y(t, x, V, u, params, omega0);
            obj.rm_odeMass = @(t, x, V, u) obj.fcn_Mass(t, x, V, u, params, omega0);

            obj.JacobiAxx = @(t, x, V, u) getJacobiAxx(t, x, V, u, params, omega0);
            obj.JacobiBxv = @(t, x, V, u) getJacobiBxv(t, x, V, u, params, omega0);
            obj.JacobiBxu = @(t, x, V, u) getJacobiBxu(t, x, V, u, params, omega0);

            obj.JacobiCyx = @(t, x, V, u) getJacobiCyx(t, x, V, u, params, omega0);
            obj.JacobiDyv = @(t, x, V, u) getJacobiDyv(t, x, V, u, params, omega0);            
            obj.JacobiDyu = @(t, x, V, u) getJacobiDyu(t, x, V, u, params, omega0);

        end
        function get_equilibrium(obj, V, u) %#ok
            obj.cv_Xequilibrium = zeros(3,1);
            obj.cv_Uequilibrium = 0;
        end
    end

    methods
        dx = fcn_dx(obj, t, x, V, u, para, omega0)
        y  = fcn_y(obj, t, x, V, u, para, omega0)
        M  = fcn_Mass(obj, t, x, V, u, para, omega0)
    end
end
