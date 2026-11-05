classdef (Sealed = true) PSS1 < controller.pss.abstract
% Power system stabilizer with a washout filter and two lead-lag blocks.
% The PSS observes the frequency deviation of the generator and drives the `Vpss`
% input of the AVR it is attached to.
%
% **Dynamic model**
% The controller is a dynamical system with state $x$, input $u$ and output $y$.
%
% **State variables** $x$ (`sv_x`)
% - `xiWS` [pu]: State of the washout filter.
% - `xi1` [pu]: State of the first lead-lag block.
% - `xi2` [pu]: State of the second lead-lag block.
%
% **Input signals** $u$ (`sv_u`)
% - `omega` [pu]: Frequency deviation of the generator.
%
% **Output signals** $y$ (`sv_y`)
% - `Vpss` [pu]: Stabilizing signal, the `Vpss` input of the AVR.
%
% **Equations** (transfer function from $\omega$ to $V_\mathrm{pss}$)
% ```math
% k_\mathrm{pss}\,\frac{t_\mathrm{WS}s}{1 + t_\mathrm{WS}s}\,\frac{1 + t_\mathrm{n1}s}{1 + t_\mathrm{d1}s}\,\frac{1 + t_\mathrm{n2}s}{1 + t_\mathrm{d2}s}
% ```
%
% The output is limited to `[Vpss_min, Vpss_max]`.
%
% <@Examples>
% Attach an AVR with this PSS to a generator and simulate a fault:
%
% ```matlab
% net = network.IEEE9bus(LocalController=false);
% gen = net.a_Bus{1}.a_Component{1};
% gen.add_local_controller(controller.avr.AVR_ST1("avr1"), controller.pss.PSS1("pss1", kpss=5));
% net.initialize;
% sc  = Scenario("fault");
% sc.add_fault("B007", [1,1.05]);
% net.add_scenario(sc);
% sol = net.simulate([0,10], sc);
% ```
%
% See also controller.avr.AVR_ST1, controller.pss.abstract

    methods
        function obj = PSS1(tag, param)
        % Create a PSS1 stabilizer with the tag "CP" + tag.
            arguments (Input)
                tag            (1,1) string % Tag suffix; the controller tag is "CP" + tag.
                param.kpss     (1,1) double = 5 % [pu] Gain of the stabilizer.
                param.tWS      (1,1) double = 10 % [s] Time constant of the washout filter.
                param.tn1      (1,1) double = 0.05 % [s] Lead time constant of the first lead-lag block.
                param.td1      (1,1) double = 0.02 % [s] Lag time constant of the first lead-lag block.
                param.tn2      (1,1) double = 3.00 % [s] Lead time constant of the second lead-lag block.
                param.td2      (1,1) double = 5.40 % [s] Lag time constant of the second lead-lag block.
                param.Vpss_min (1,1) double = -Inf % [pu] Lower limit of the output.
                param.Vpss_max (1,1) double = Inf % [pu] Upper limit of the output.
                
            end            
            arguments (Output)
                obj % PSS1 object.
            end
            obj@controller.pss.abstract(tag)                                    
            
            obj.para_dynamics.add_entry(   "kpss", param.kpss    , "double", ...
                                            "tWS", param.tWS     , "double", ...
                                            "tn1", param.tn1     , "double", ...
                                            "td1", param.td1     , "double", ...
                                            "tn2", param.tn2     , "double", ...
                                            "td2", param.td2     , "double", ...
                                       "Vpss_max", param.Vpss_max, "double", ...
                                       "Vpss_min", param.Vpss_min, "double");          

            obj.key      = "pss";
            obj.sv_x    = ["xiWS"; "xi1"; "xi2"];
            obj.sv_u    = "omega";   
            obj.sv_y    = "Vpss";
            obj.sv_para = ["kpss"; "tWS"; "tn1"; "td1"; "tn2"; "td2"; "Vpss_min"; "Vpss_max"];
        end        
        
        function get_equilibrium(obj, V, u) %#ok
        % Set the equilibrium state and input of the PSS to 0.
            arguments (Input)
                obj
                V    % [pu] Complex terminal voltage of the generator at the equilibrium (unused).
                u    % [pu] Equilibrium input of the generator (unused).
            end
            obj.rv_Xequilibrium = zeros(3,1);
            obj.rv_Uequilibrium = 0;
        end
    end

    methods (Static)
        dx   = fcn_dx(t, x, V, I, u, param, omega0)
        Vpss = fcn_y(t, x, V, I, u, param, omega0)
        Mass = fcn_Mass(t, x, V, I, u, param, omega0)

        [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0)
        [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0)
    end    
end
