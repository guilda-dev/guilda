classdef (Sealed = true) PSS1 < LocalController
    properties (Constant, Hidden=true)             
        str_x    = ["xiWS"; "xi1"; "xi2"];
        str_u    = ["omega"];   
        str_y    = ["Vpss"];
        str_para = ["kpss"; "tWS"; "tn1"; "td1"; "tn2"; "td2"; "Vpss_min"; "Vpss_max"];
    end    
    methods
        function obj = PSS1(param)
            arguments                
                param.kpss     (1,1) double = 20
                param.tWS      (1,1) double = 10
                param.tn1      (1,1) double = 0.05
                param.td1      (1,1) double = 0.02
                param.tn2      (1,1) double = 3.00
                param.td2      (1,1) double = 5.40
                param.Vpss_min (1,1) double = -inf
                param.Vpss_max (1,1) double = inf
                
            end            
            obj@LocalController("CP")                                    
            
            obj.para_dynamics.add_entry(   "kpss", param.kpss    , "double", ...
                                            "tWS", param.tWS     , "double", ...
                                            "tn1", param.tn1     , "double", ...
                                            "td1", param.td1     , "double", ...
                                            "tn2", param.tn2     , "double", ...
                                            "td2", param.td2     , "double", ...
                                       "Vpss_max", param.Vpss_max, "double", ...
                                       "Vpss_min", param.Vpss_min, "double");
            
            params   = obj.tab_parameter.dynamics{:,obj.str_para};
            obj.fv_odeDiff = @(t, x, V, u) obj.fcn_dx(t, x, V, u, params);
            obj.fv_odeY    = @(t, x, V, u) obj.fcn_y(t, x, V, u, params);
            obj.rm_odeMass = @(t, x, V, u) obj.fcn_Mass(t, x, V, u, params);

            obj.JacobiA = @(t, x, V, u) A_PSS1(t, x, V, u, param);
            obj.JacobiB = @(t, x, V, u) B_PSS1(t, x, V, u, param);
            obj.JacobiC = @(t, x, V, u) C_PSS1(t, x, V, u, param);
            obj.JacobiD = @(t, x, V, u) D_PSS1(t, x, V, u, param);

        end        
        function [cv_Xequilibrium, cv_Uequilibrium] = get_equilibrium(obj, V, u) %#ok
            cv_Xequilibrium = obj.dic_Xequilibrium.insert(obj.str_x, zeros(3,1));
            cv_Uequilibrium = obj.dic_Uequilibrium.insert(obj.str_u,          0);
        end
    end

    methods
        dx = fcn_dx(obj, t, x, V, u, para, omega0)
        y  = fcn_y(obj, t, x, V, u, para, omega0)
        M  = fcn_Mass(obj, t, x, V, u, para, omega0)
    end
end
