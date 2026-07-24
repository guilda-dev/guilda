classdef (Sealed = true) AVR_DC1 < controller.avr.base
    
    methods
        function obj = AVR_DC1(tag, param)
            arguments               
                tag           (1,1) string 
                param.ttr     (1,1) double = 0.01
                param.tap     (1,1) double = 0.2
                param.kap     (1,1) double = 0
                param.Vap_max (1,1) double = Inf
                param.Vap_min (1,1) double = -Inf  
                param.tex     (1,1) double = 0.314
                param.aex1    (1,1) double = 1
                param.aex2    (1,1) double = 0.0039                
                param.bex     (1,1) double = 1.555
                param.tst     (1,1) double = 0.35
                param.kst     (1,1) double = 0.063                
            end            
            obj@controller.avr.base(tag)                                 
            
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

            obj.key      = "avr";
            obj.sv_x    = ["Vtr";"Vap"; "Vfld"; "Vst"];
            obj.sv_u    = ["Vref";"Vpss"];   
            obj.sv_y    = "Vfield";
            obj.sv_para = ["ttr"; "Vap_max"; "Vap_min"; "kap"; "tap"; "aex1"; "aex2"; "tex"; "bex"; "kst"; "tst"];              

            obj.set_odefcn(60);
        end        

        function get_equilibrium(obj, V, u)                   
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

            obj.rv_Xequilibrium = [Vtr_st; Vap_st; Vfld_st; Vst_st];
            obj.rv_Uequilibrium = [Vref_st;Vpss_st];            

            obj.c_Vequilibrium = V;
            obj.c_Iequilibrium = [];
        end
        function set_PSS(obj, cls)
            obj.a_LocalController{1} = cls;
            obj.l_hasController = true;
        end
    end

    methods       
        M  = fcn_Mass(obj, t, x, V, I, u, param, omega0)
        dx = fcn_dx(obj, t, x, V, I, u, param, omega0)
        y  = fcn_y(obj, t, x, V, I, u, param, omega0)                
    end

    methods (Static)
        [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0)
        [Cix,Div,Dii,Diu] = Jacobi_I(t,x,V,I,u,param,omega0)
        [Cyx,Dyv,Dyi,Dyu] = Jacobi_y(t,x,V,I,u,param,omega0)
    end
end