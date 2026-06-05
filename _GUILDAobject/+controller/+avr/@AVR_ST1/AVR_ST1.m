classdef (Sealed = true) AVR_ST1 < controller.avr.base
    
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
            obj@controller.avr.base(tag)                                 
            
            obj.para_dynamics.add_entry(    "ttr", param.ttr    , "double", ...
                                        "Vap_max", param.Vap_max, "double", ...
                                        "Vap_min", param.Vap_min, "double", ...
                                            "kap", param.kap    , "double", ...
                                            "tap", param.tap    , "double", ...                                           
                                            "kst", param.kst    , "double", ...
                                            "tst", param.tst    , "double");                       

            obj.key      = "avr";
            obj.str_x    = ["Vtr";"Vap";"Vst"];
            obj.str_u    = ["Vref";"Vpss"];   
            obj.str_y    = "Vfield";
            obj.str_para = ["ttr"; "Vap_max"; "Vap_min"; "kap"; "tap"; "kst"; "tst"];

        end        

        function set_odefcn(obj, omega0)            
            params = obj.tab_parameter.dynamics{:,obj.str_para}.';
            obj.fv_odeDiff = @(t,x,V,I,u) obj.fcn_dx(t, x, V, I, u, params, omega0);            
            obj.rm_odeMass = @(t,x,V,I,u) obj.fcn_Mass(t, x, V, I, u, params, omega0);
            obj.fv_odeY    = @(t,x,V,I,u) obj.fcn_y(t, x, V, I, u, params, omega0);

            obj.JacobiAxx = @(t,x,V,I,u) getJacobiAxx(t, x, V, I, u, params, omega0);
            obj.JacobiBxv = @(t,x,V,I,u) getJacobiBxv(t, x, V, I, u, params, omega0);
            obj.JacobiBxi = @(t,x,V,I,u) getJacobiBxi(t, x, V, I, u, params, omega0);
            obj.JacobiBxu = @(t,x,V,I,u) getJacobiBxu(t, x, V, I, u, params, omega0);

            obj.JacobiCyx = @(t,x,V,I,u) getJacobiCyx(t, x, V, I, u, params, omega0);
            obj.JacobiDyv = @(t,x,V,I,u) getJacobiDyv(t, x, V, I, u, params, omega0);            
            obj.JacobiDyi = @(t,x,V,I,u) getJacobiDyi(t, x, V, I, u, params, omega0);
            obj.JacobiDyu = @(t,x,V,I,u) getJacobiDyu(t, x, V, I, u, params, omega0);

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

            obj.cv_Xequilibrium = [Vtr_st; Vap_st; Vst_st];
            obj.cv_Uequilibrium = [Vref_st;Vpss_st];            

            obj.c_Vequilibrium = V;
            obj.c_Iequilibrium = [];
        end
        function set_PSS(obj, cls)
            obj.a_LocalController{1} = cls;
            obj.isController = true;
        end
    end

    methods       
        M  = fcn_Mass(obj, t, x, V, I, u, param, omega0)
        dx = fcn_dx(obj, t, x, V, I, u, param, omega0)
        y  = fcn_y(obj, t, x, V, I, u, param, omega0)                
    end
end