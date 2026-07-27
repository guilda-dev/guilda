classdef (Sealed = true) AVR_ST1 < controller.avr.abstract
    
    methods
        function obj = AVR_ST1(tag, param)
            arguments               
                tag           (1,1) string                 
                param.ttr     (1,1) double = 0
                param.tap     (1,1) double = 0.05
                param.kap     (1,1) double = 30
                param.Vap_max (1,1) double = Inf
                param.Vap_min (1,1) double = -Inf                                  
                param.tst     (1,1) double = 0
                param.kst     (1,1) double = 0
            end            
            obj@controller.avr.abstract(tag)                                 
            
            obj.para_dynamics.add_entry(    "ttr", param.ttr    , "double", ...
                                        "Vap_max", param.Vap_max, "double", ...
                                        "Vap_min", param.Vap_min, "double", ...
                                            "kap", param.kap    , "double", ...
                                            "tap", param.tap    , "double", ...                                           
                                            "kst", param.kst    , "double", ...
                                            "tst", param.tst    , "double");                       

            obj.key      = "avr";
            obj.sv_x    = ["Vtr";"Vap";"Vst"];
            obj.sv_u    = ["Vref";"Vpss"];   
            obj.sv_y    = "Vfield";
            obj.sv_para = ["ttr"; "Vap_max"; "Vap_min"; "kap"; "tap"; "kst"; "tst"];  

            obj.set_odefcn(60)
        end        
        
        function get_equilibrium(obj, V, u)                   
            tab = obj.tab_parameter.dynamics;
            Vap_max = tab{:, 'Vap_max'};
            Vap_min = tab{:, 'Vap_min'};            
            kap     = tab{:, 'kap'    };

            Vap_st = u(2);            
            
            if Vap_st <= Vap_min || Vap_st >= Vap_max
                obj.error(msg('GUILDA:AVR_DC1:InvalidValueRange'))
            end

            Vst_st  = 0;
            Vcom_st = Vap_st/kap;                        
            Vtr_st  = abs(V);            
            Vref_st = Vcom_st + Vtr_st;
            Vpss_st = 0;

            obj.rv_Xequilibrium = [Vtr_st; Vap_st; Vst_st];
            obj.rv_Uequilibrium = [Vref_st;Vpss_st];            

            obj.c_Vequilibrium = V;
            obj.c_Iequilibrium = [];
        end

        function set_PSS(obj, cls)
            obj.a_LocalController{1} = cls;
            obj.l_hasController = true;
        end
    end

    methods (Static)      
        M  = fcn_Mass(t, x, V, I, u, param, omega0)
        dx = fcn_dx(t, x, V, I, u, param, omega0)
        y  = fcn_y(t, x, V, I, u, param, omega0)                
        
        [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0)        
        [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0)
    end
end