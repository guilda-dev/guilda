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
% The output is `Vfield = Vfld`. Two non-windup limits (IEEE Std 421.5-2016, Annex
% E.3) freeze a state while it is at or beyond a limit and its derivative points
% outward: `Vap` at `Vap_max` or `Vap_min`, and `Vfld` at `Vfld_max` or `Vfld_min` (a
% limit on the field voltage). The logical parameter `Limiter` switches both limits:
% true (the default) applies them, false ignores them (the same as all four limits at
% +-Inf).
%
% The model is a simplified form of the Type DC1A model of IEEE Std 421.5-2016
% (represented in that edition by Type DC1C, Clause 6.3). It leaves out:
% - the lead-lag block (TC, TB)
% - the load compensation (RC, XC)
% - the UEL, OEL and SCL inputs and their gates
%
% It adds the non-windup upper limit `Vfld_max` on the field voltage, which DC1A and DC1C
% do not have (EFDmin of DC1C corresponds to `Vfld_min`). The exciter saturation is
% SE(EFD) = `aex2`·exp(`bex`·EFD), with `aex1` in the role of KE, instead of the two-point
% data E1, SE(E1), E2, SE(E2).
%
% <@Citations>
% - 石崎孝幸 編著, 川口貴弘, 河辺賢一 著, 『電力系統のシステム制御工学
%   ―システム数理とMATLABシミュレーション―』 (計測・制御セレクションシリーズ 4),
%   計測自動制御学会 編, コロナ社, 2022, Sect. 5.3.2, ISBN 978-4-339-03384-7,
%   [publisher page](https://www.coronasha.co.jp/np/isbn/9784339033847/).
% - *IEEE Recommended Practice for Excitation System Models for Power System Stability
%   Studies*, IEEE Std 421.5-2016, 2016, Clauses 6.2–6.3, Fig. 4, doi:
%   [10.1109/IEEESTD.2016.7553421](https://doi.org/10.1109/IEEESTD.2016.7553421).
% - P. Kundur, *Power System Stability and Control*. New York, NY, USA: McGraw-Hill, 1994,
%   Sect. 8.6, ISBN 0-07-035958-X.
% - P. M. Anderson and A. A. Fouad, *Power System Control and Stability*, 2nd ed.
%   Piscataway, NJ, USA: IEEE Press / Wiley-Interscience, 2003, doi:
%   [10.1109/9780470545577](https://doi.org/10.1109/9780470545577).
% - F. Milano, *Power System Modelling and Scripting* (Power Systems). Berlin Heidelberg,
%   Germany: Springer, 2010, Sect. 16.2.1, pp. 363–364, doi:
%   [10.1007/978-3-642-13669-6](https://doi.org/10.1007/978-3-642-13669-6).
% - 電気学会 電力系統モデル標準化調査専門委員会, 「電力系統の標準モデル」,
%   電気学会技術報告 第754号, 1999.
% - 電気学会 電力・エネルギー部門, 「電力系統の標準モデル」,
%   [https://www.iee.jp/pes/ele_systems/base_model](https://www.iee.jp/pes/ele_systems/base_model)
%   (accessed 2026-11-25).
%
% <@Examples>
% Attach the AVR and a PSS to a generator and simulate a fault:
%
% ```matlab
% net = network.IEEE9bus(LocalController=false);
% gen = net.a_Bus{1}.a_Component{1};
% gen.add_local_controller("avr-DC1", parameter=struct(kap=20));
% gen.add_local_controller("pss-PSS1");
% net.initialize;
% sc  = net.add_scenario("fault");
% sc.add_fault("B007", [1,1.05]);
% sol = net.simulate("fault");
% ```
%
% See also controller.avr.AVR_ST1, controller.pss.PSS1, controller.avr.abstract
    
    properties (Constant, Hidden) % Model definition
        key = "avr-DC1"  % Model key that selects this class in `Component.add_local_controller`.
    end

    methods (Access={?Component})
        function obj = AVR_DC1(tag, param)
        % Create an AVR_DC1 regulator with the tag "CA" + tag.
            arguments (Input)
                tag           (1,1) string           % Tag suffix; the controller tag is "CA" + tag.
                param.ttr     (1,1) double = 0.01    % [s] Time constant of the voltage transducer.
                param.tap     (1,1) double = 0.2     % [s] Time constant of the amplifier.
                param.kap     (1,1) double = 20      % [pu] Gain of the amplifier (nonzero: the equilibrium needs Vap/kap).
                param.Vap_max (1,1) double = Inf     % [pu] Upper limit of the amplifier output.
                param.Vap_min (1,1) double = -Inf    % [pu] Lower limit of the amplifier output.
                param.tex     (1,1) double = 0.314   % [s] Time constant of the exciter.
                param.aex1    (1,1) double = 1       % [pu] Linear coefficient of the exciter saturation.
                param.aex2    (1,1) double = 0.0039  % [pu] Exponential coefficient of the exciter saturation.
                param.bex     (1,1) double = 1.555   % [1/pu] Exponent of the exciter saturation.
                param.tst     (1,1) double = 0.35    % [s] Time constant of the stabilizing feedback.
                param.kst     (1,1) double = 0.063   % [pu] Gain of the stabilizing feedback.
                param.Vfld_max (1,1) double = Inf    % [pu] Upper limit of the field voltage (exciter output).
                param.Vfld_min (1,1) double = -Inf   % [pu] Lower limit of the field voltage (exciter output).
                param.Limiter (1,1) logical = true   % true to apply the limits of Vap and Vfld; false ignores them.
            end            
            arguments (Output)
                obj  % AVR_DC1 object.
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
                "Vfld_min", param.Vfld_min, ...
                 "Limiter", param.Limiter));
            obj.sv_x    = ["Vtr";"Vap"; "Vfld"; "Vst"];
            obj.sv_u    = ["Vref";"Vpss"];   
            obj.sv_y    = "Vfield";
            obj.sv_para = ["ttr"; "Vap_max"; "Vap_min"; "kap"; "tap"; "aex1"; "aex2"; "tex"; "bex"; "kst"; "tst"; "Vfld_max"; "Vfld_min"; "Limiter"];              
        end        
    end    

    methods (Static)
        M  = fcn_Mass(t, x, V, u, param, omega0)
        dx = fcn_dx(t, x, V, u, param, omega0)
        y  = fcn_y(t, x, V, u, param, omega0)                
        [Axx,Bxv,Bxu] = Jacobi_dx(t,x,V,u,param,omega0)        
        [Cyx,Dyv,Dyu] = Jacobi_Y(t,x,V,u,param,omega0)
    end
end
