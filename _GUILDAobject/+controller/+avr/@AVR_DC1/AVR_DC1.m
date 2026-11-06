classdef (Sealed = true) AVR_DC1 < controller.avr.abstract
% Automatic voltage regulator with a DC exciter (IEEE type DC1).
% The AVR observes the terminal voltage $V$ [pu] of the generator it is attached to
% and drives the field voltage input of the generator.
%
% **Dynamic model**
% The controller is a dynamical system with state $x$, input $u$ and output $y$.
%
% **State variables** $x$ (`sv_x`)
% - `Vtr` [pu]: Transducer output.
% - `Vap` [pu]: Amplifier output.
% - `Vfld` [pu]: Exciter output (field voltage).
% - `Vst` [pu]: Stabilizing feedback.
%
% **Input signals** $u$ (`sv_u`)
% - `Vref` [pu]: Voltage reference.
% - `Vpss` [pu]: Output of the attached PSS (0 without a PSS).
%
% **Output signals** $y$ (`sv_y`)
% - `Vfield` [pu]: Field voltage, the `Vfield` input of the generator.
%
% **Equations** (transducer, amplifier, exciter, stabilizing feedback)
% ```math
% \left\{
% \begin{aligned}
% t_\mathrm{tr}\dot{V}_\mathrm{tr} &= -V_\mathrm{tr} + |V| \\
% t_\mathrm{ap}\dot{V}_\mathrm{ap} &= -V_\mathrm{ap} + k_\mathrm{ap}\,(V_\mathrm{ref} + V_\mathrm{pss} - V_\mathrm{tr} - V_\mathrm{st}) \\
% t_\mathrm{ex}\dot{V}_\mathrm{fld} &= -\left(a_\mathrm{ex1} + a_\mathrm{ex2}\,e^{b_\mathrm{ex}V_\mathrm{fld}}\right)V_\mathrm{fld} + V_\mathrm{ap} \\
% t_\mathrm{st}\dot{V}_\mathrm{st} &= -V_\mathrm{st} + k_\mathrm{st}\,\dot{V}_\mathrm{fld}
% \end{aligned}
% \right.
% ```
%
% The output is `Vfield = Vfld`. Two non-windup limits freeze a state while it is out
% of its range and the input drives it further out: `Vap` outside
% `(Vap_min, Vap_max)`, and `Vfld` at or beyond `Vfld_max` or `Vfld_min` (a limit on
% the field voltage).
%
% <@Examples>
% Attach the AVR and a PSS to a generator and simulate a fault:
%
% ```matlab
% net = network.IEEE9bus(LocalController=false);
% gen = net.a_Bus{1}.a_Component{1};
% gen.add_local_controller(controller.avr.AVR_DC1("avr1", kap=20), controller.pss.PSS1("pss1"));
% net.initialize;
% sc  = Scenario("fault");
% sc.add_fault("B007", [1,1.05]);
% net.add_scenario(sc);
% sol = net.simulate([0,10], sc);
% ```
%
% See also controller.avr.AVR_ST1, controller.pss.PSS1, controller.avr.abstract
    
    methods
        function obj = AVR_DC1(tag, param)
        % Create an AVR_DC1 regulator with the tag "CA" + tag.
            arguments (Input)
                tag           (1,1) string % Tag suffix; the controller tag is "CA" + tag.
                param.ttr     (1,1) double = 0.01 % [s] Time constant of the voltage transducer.
                param.tap     (1,1) double = 0.2 % [s] Time constant of the amplifier.
                param.kap     (1,1) double = 0 % [pu] Gain of the amplifier.
                param.Vap_max (1,1) double = Inf % [pu] Upper limit of the amplifier output.
                param.Vap_min (1,1) double = -Inf % [pu] Lower limit of the amplifier output.
                param.tex     (1,1) double = 0.314 % [s] Time constant of the exciter.
                param.aex1    (1,1) double = 1 % [pu] Linear coefficient of the exciter saturation.
                param.aex2    (1,1) double = 0.0039 % [pu] Exponential coefficient of the exciter saturation.
                param.bex     (1,1) double = 1.555 % [1/pu] Exponent of the exciter saturation.
                param.tst     (1,1) double = 0.35 % [s] Time constant of the stabilizing feedback.
                param.kst     (1,1) double = 0.063 % [pu] Gain of the stabilizing feedback.
                param.Vfld_max (1,1) double = Inf % [pu] Upper limit of the field voltage (exciter output).
                param.Vfld_min (1,1) double = -Inf % [pu] Lower limit of the field voltage (exciter output).
            end            
            arguments (Output)
                obj % AVR_DC1 object.
            end
            obj@controller.avr.abstract(tag)                                 
            
            obj.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", obj.a_Parameter)} = Parameter(obj, "dynamics", struct( ...
                     "ttr", param.ttr, ...
                 "Vap_max", param.Vap_max, ...
                 "Vap_min", param.Vap_min, ...
                     "kap", param.kap, ...
                     "tap", param.tap, ...
                    "aex1", param.aex1, ...
                    "aex2", param.aex2, ...
                     "tex", param.tex, ...
                     "bex", param.bex, ...
                     "kst", param.kst, ...
                     "tst", param.tst, ...
                "Vfld_max", param.Vfld_max, ...
                "Vfld_min", param.Vfld_min));

            obj.key     = "avr";
            obj.sv_x    = ["Vtr";"Vap"; "Vfld"; "Vst"];
            obj.sv_u    = ["Vref";"Vpss"];   
            obj.sv_y    = "Vfield";
            obj.sv_para = ["ttr"; "Vap_max"; "Vap_min"; "kap"; "tap"; "aex1"; "aex2"; "tex"; "bex"; "kst"; "tst"; "Vfld_max"; "Vfld_min"];              
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
