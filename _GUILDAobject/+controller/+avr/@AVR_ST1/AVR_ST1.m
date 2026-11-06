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
            
            obj.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", obj.a_Parameter)}.add_entry( ...
                    "ttr", param.ttr    , "double", ...
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
    end

    methods (Static)      
        M  = fcn_Mass(t, x, V, I, u, param, omega0)
        dx = fcn_dx(t, x, V, I, u, param, omega0)
        y  = fcn_y(t, x, V, I, u, param, omega0)                
        [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0)        
        [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0)
    end
end
