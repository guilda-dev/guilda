classdef (Sealed = true) AVR_ST1 < controller.avr.abstract
% Automatic voltage regulator with a static exciter (IEEE type ST1).
% The AVR observes the terminal voltage $V$ [pu] of the generator it is attached to
% and drives the field voltage input of the generator.
%
% **Dynamic model**
% The controller is a dynamical system with state $x$, input $u$ and output $y$.
%
% **State variables** $x$ (`sv_x`)
% - `Vtr` [pu]: Transducer output.
% - `Vap` [pu]: Amplifier output.
% - `Vst` [pu]: Stabilizing feedback.
%
% **Input signals** $u$ (`sv_u`)
% - `Vref` [pu]: Voltage reference.
% - `Vpss` [pu]: Output of the attached PSS (0 without a PSS).
%
% **Output signals** $y$ (`sv_y`)
% - `Vfield` [pu]: Field voltage, the `Vfield` input of the generator.
%
% **Equations** (transducer, amplifier, stabilizing feedback)
% ```math
% \left\{
% \begin{aligned}
% t_\mathrm{tr}\dot{V}_\mathrm{tr} &= -V_\mathrm{tr} + |V| \\
% t_\mathrm{ap}\dot{V}_\mathrm{ap} &= -V_\mathrm{ap} + k_\mathrm{ap}\,(V_\mathrm{ref} + V_\mathrm{pss} - V_\mathrm{tr} - V_\mathrm{st}) \\
% t_\mathrm{st}\dot{V}_\mathrm{st} &= -V_\mathrm{st} + k_\mathrm{st}\,\dot{V}_\mathrm{ap}
% \end{aligned}
% \right.
% ```
%
% The output is `Vfield = Vap` limited to `[Vap_min, Vap_max]`. With the defaults
% (`ttr = 0`, `tst = kst = 0`) the AVR is the first-order lag `kap/(1 + tap*s)`.
%
% <@Examples>
% Attach the AVR and a PSS to a generator and simulate a fault:
%
% ```matlab
% net = network.IEEE9bus(LocalController=false);
% gen = net.a_Bus{1}.a_Component{1};
% gen.add_local_controller(controller.avr.AVR_ST1("avr1", kap=30), controller.pss.PSS1("pss1"));
% net.initialize;
% sc  = Scenario("fault");
% sc.add_fault("B007", [1,1.05]);
% net.add_scenario(sc);
% sol = net.simulate([0,10], sc);
% ```
%
% See also controller.avr.AVR_DC1, controller.pss.PSS1, controller.avr.abstract
    
    methods
        function obj = AVR_ST1(tag, param)
        % Create an AVR_ST1 regulator with the tag "CA" + tag.
            arguments (Input)
                tag           (1,1) string % Tag suffix; the controller tag is "CA" + tag.
                param.ttr     (1,1) double = 0 % [s] Time constant of the voltage transducer.
                param.tap     (1,1) double = 0.05 % [s] Time constant of the amplifier.
                param.kap     (1,1) double = 30 % [pu] Gain of the amplifier.
                param.Vap_max (1,1) double = Inf % [pu] Upper limit of the output.
                param.Vap_min (1,1) double = -Inf % [pu] Lower limit of the output.
                param.tst     (1,1) double = 0 % [s] Time constant of the stabilizing feedback.
                param.kst     (1,1) double = 0 % [pu] Gain of the stabilizing feedback.
            end            
            arguments (Output)
                obj % AVR_ST1 object.
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
        end        
        
        function get_equilibrium(obj, V, u)                   
        % Set the equilibrium state and reference voltage of the AVR and of its PSS.
        % The reference `Vref` is chosen so that the field voltage equals the
        % generator's equilibrium field voltage `u(2)`; `Vpss` is 0 at the equilibrium.
        % An error is raised when the required amplifier output is outside `[Vap_min, Vap_max]`.
            arguments (Input)
                obj
                V    % [pu] Complex terminal voltage of the generator at the equilibrium.
                u    % [pu] Equilibrium input of the generator `[Pmech; Vfield]`.
            end
            tab = obj.tab_parameter.dynamics;
            Vap_max = tab{:, 'Vap_max'};
            Vap_min = tab{:, 'Vap_min'};            
            kap     = tab{:, 'kap'    };

            Vap_st = u(2);            
            
            if Vap_st <= Vap_min || Vap_st >= Vap_max
                error(msg("GUILDA:AVR_ST1:InvalidValueRange", char(obj.str_tag), num2str(Vap_st), num2str(Vap_min), num2str(Vap_max)))
            end

            Vst_st  = 0;
            Vcom_st = Vap_st/kap;                        
            Vtr_st  = abs(V);            
            Vref_st = Vcom_st + Vtr_st;
            Vpss_st = 0;

            obj.rv_Xequilibrium = [Vtr_st; Vap_st; Vst_st];
            obj.rv_Uequilibrium = [Vref_st;Vpss_st];            

            cellfun(@(c) c.get_equilibrium(V,u), obj.a_LocalController);
        end

        function set_PSS(obj, cls)
        % Attach a PSS to the AVR.
            arguments (Input)
                obj
                cls  % PSS object (a controller.pss.abstract subclass).
            end
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