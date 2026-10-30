classdef broadcast_PI_AGC < GlobalController    
% Automatic generation control that broadcasts one PI command to several generators.
% The controller observes the frequency deviations `omega_i` [pu] of the
% controlled generators and outputs a mechanical power command `Pmech_i` [pu] to
% the `Pmech` input of each of them:
%
% - broadcast frequency: `w = sum(beta_i*omega_i)`
% - integrator: `dxi/dt = w`
% - command: `Pmech_i = -alpha_i*(kP*w + kI*xi)`
%
% `alpha_i` shares the command among the generators and `beta_i` weights their
% frequency deviations.
%
% <@Examples>
% Control the generators at buses 1 and 2 and simulate a fault:
%
% ```matlab
% net = network.IEEE9bus();
% g1  = net.a_Bus{1}.a_Component{1};
% g2  = net.a_Bus{2}.a_Component{1};
% agc = controller.agc.broadcast_PI_AGC(net, "agc", g1, g2, kP=100, kI=500);
% net.add_global_controller(agc);
% net.initialize;
% ev  = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B007");
% sol = net.simulate([0,10], ev);
% ```
%
% See also GlobalController, PowerNetwork.add_global_controller

    properties (Constant, Hidden)
        key  = "agc"
        sv_x = "xi"
        sv_u = "omega"
        sv_y = "Pmech"
        sv_para = ["alpha","beta","kP","kI"]
    end           
    
    methods
        function obj = broadcast_PI_AGC(net, tag, varargin, opt)
        % Create the AGC for the generators given after the tag.
            arguments
                net % PowerNetwork that contains the controlled generators.
                tag % Tag of the controller.
            end
            arguments (Input,Repeating)
                varargin % Controlled generators, each a generator object or its tag.
            end
            arguments
                opt.alpha (:,1) double = 1 % [pu] Share of the command for each controlled generator; a scalar applies to all.
                opt.beta  (:,1) double = 1 % [pu] Weight of each generator's frequency deviation; a scalar applies to all.
                opt.kP    (1,1) double = 100 % [pu] Proportional gain.
                opt.kI    (1,1) double = 500 % [1/s] Integral gain.
            end 
            arguments (Output)
                obj % broadcast_PI_AGC object.
            end
            obj@GlobalController(net, tag, varargin{:})            

            % A scalar alpha or beta (e.g. the default) applies to every controlled unit
            nCU = max(numel(obj.controlledUnits), 1);
            if isscalar(opt.alpha); opt.alpha = repmat(opt.alpha, [nCU,1]); end
            if isscalar(opt.beta);  opt.beta  = repmat(opt.beta,  [nCU,1]); end

            na = numel(opt.alpha);
            nb = numel(opt.beta);
            if na ~= nCU || nb ~= nCU
                error("GUILDA:broadcast_PI_AGC:InvalidSize", ...
                      "alpha and beta must be scalars or have one element per controlled unit (%d).", nCU)
            end            

            obj.para_dynamics.add_entry("alpha", opt.alpha             , "double", ...
                                         "beta", opt.beta              , "double", ...
                                           "kP", repmat(opt.kP, [na,1]), "double", ...
                                           "kI", repmat(opt.kI, [na,1]), "double");                        
            obj.set_odefcn(obj.r_Hz);
        end

        function [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj)
        % Return the equilibrium of the AGC: zero integrator state and zero frequency deviations.
            arguments (Output)
                rv_Xequilibrium % [pu*s] Equilibrium integrator state (0).
                rv_Uequilibrium % [pu] Equilibrium frequency deviations (0), one per controlled generator.
            end
            nCU = numel(obj.controlledUnits);
            rv_Xequilibrium = 0;
            rv_Uequilibrium = zeros(nCU,1);
        end                                        
    end
    
    methods (Static)
        dx = fcn_dx(t, x, V, I, u, param, omega0)
        y  = fcn_y(t, x, V, I, u, param, omega0)
        M  = fcn_Mass(t, x, V, I, u, param, omega0)

        [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0);
        [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0);
    end
end