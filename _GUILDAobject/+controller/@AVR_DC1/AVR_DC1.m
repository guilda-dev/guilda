classdef (Sealed = true) AVR_DC1 < LocalController
    properties (Constant, Hidden=true)
        key      = "avr"
        str_x    = ["Vtr";"Vap"; "Vfld"; "Vst"];
        str_u    = ["Vref";"Vpss"];   
        str_y    = ["Vfld"];
        str_para = ["ttr"; "Vap_max"; "Vap_min"; "kap"; "tap"; "aex1"; "aex2"; "tex"; "bex"; "kst"; "tst"];
    end    
    methods
        function obj = AVR_DC1(param)
            arguments                
                param.ttr     (1,1) double = 0.00
                param.Vap_max (1,1) double = 1
                param.Vap_min (1,1) double = -1
                param.kap     (1,1) double = 57.1
                param.tap     (1,1) double = 0.05
                param.aex1    (1,1) double = -0.045
                param.aex2    (1,1) double = 0.0012
                param.tex     (1,1) double = 0.50
                param.bex     (1,1) double = 1.21
                param.kst     (1,1) double = 0.08
                param.tst     (1,1) double = 1.00
            end            
            obj@LocalController("CA")                                 
            
            obj.para_dynamics.add_entry(    "ttr", param.ttr    , "double", ...
                                        "Vap_max", param.Vap_max, "double", ...
                                        "Vap_min", param.Vap_min, "double", ...
                                            "kap", param.kap    , "double", ...
                                            "tap", param.tap    , "double", ...
                                           "aex1", param.aex1   , "double", ...
                                           "aex2", param.aex2   , "double", ...
                                            "tex", param.tex    , "double", ...
                                            "bex", param.bex    , "double", ...
                                            "kst", param.kst    , "double", ...
                                            "tst", param.tst    , "double");                       

        end        

        function set_fcn(obj, omega0)            
            params = obj.tab_parameter.dynamics{:,obj.str_para}.';
            obj.fv_odeDiff = @(t, x, V, u) obj.fcn_dx(t, x, V, u, params, omega0);
            obj.fv_odeConY = @(t, x, V, u) obj.fcn_y(t, x, V, u, params, omega0);
            obj.rm_odeMass = @(t, x, V, u) obj.fcn_Mass(t, x, V, u, params, omega0);

            obj.JacobiA = @(t, x, V, u) A_AVR_DC1(t, x, V, u, params, omega0);
            obj.JacobiB = @(t, x, V, u) B_AVR_DC1(t, x, V, u, params, omega0);
            obj.JacobiC = @(t, x, V, u) C_AVR_DC1(t, x, V, u, params, omega0);
            obj.JacobiD = @(t, x, V, u) D_AVR_DC1(t, x, V, u, params, omega0);

        end
        function [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, V, u)                   
            tab = obj.tab_parameter.dynamics;
            Vap_max = tab{:, 'Vap_max'};
            Vap_min = tab{:, 'Vap_min'};
            aex1    = tab{:, 'aex1'   };
            aex2    = tab{:, 'aex2'   };
            bex     = tab{:, 'bex'    };
            kap     = tab{:, 'kap'    };

            Vfld_st = u(2);
            Vap_st  = Vfld_st*(aex1 + aex2*exp(bex*Vfld_st));
            
            if Vap_st <= Vap_min || Vap_st >= Vap_max
                obj.error(msg('GUILDA:AVR_DC1:InvalidValueRange'))
            end
            Vcom_st = Vap_st/kap;            
            Vref_st = abs(V) + Vcom_st;
            Vtr_st  = abs(V);
            Vst_st  = 0;
            Vpss_st = 0;

            rv_Xequilibrium = [Vtr_st; Vap_st; Vfld_st; Vst_st];
            rv_Uequilibrium = [Vref_st;Vpss_st];            
        end
        function set_PSS(obj, cls)
            obj.a_LocalController{1} = cls;
            obj.isController = true;
        end
    end

    methods       
        M  = fcn_Mass(obj, sv_x, sv_V, sv_I, sv_u, sv_y)
        dx = fcn_dx(obj, sv_x, sv_V, sv_I, sv_u, sv_y)
        y  = fcn_y(obj, sv_x, sv_V, sv_I, sv_u, sv_y)                
    end
end