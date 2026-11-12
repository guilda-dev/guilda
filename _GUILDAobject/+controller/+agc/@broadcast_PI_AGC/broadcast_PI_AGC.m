classdef broadcast_PI_AGC < GlobalController    
% Automatic generation control that broadcasts one PI command to several generators.
% The controller observes the frequency deviations of the controlled generators and
% drives the `Pmech` input of each of them.
%
% **Dynamic model**
% The controller is a dynamical system with state $x$, input $u$ and output $y$.
%
% **State variables** $x$ (`sv_x`)
% - `xi`: Integral of the broadcast frequency.
%
% **Input signals** $u$ (`sv_u`, one per controlled generator $i$)
% - `omega` [pu]: Frequency deviation $\omega_i$ of the generator.
%
% **Output signals** $y$ (`sv_y`, one per controlled generator $i$)
% - `Pmech` [pu]: Mechanical power command $P_{\mathrm{mech},i}$, added to the `Pmech`
%   input of the generator.
%
% **Equations**
% ```math
% \dot{\xi} = w, \qquad w = \sum_i \beta_i\,\omega_i, \qquad P_{\mathrm{mech},i} = -\alpha_i\,(k_P\,w + k_I\,\xi)
% ```
%
% $\alpha_i$ (`alpha`) shares the command among the generators and $\beta_i$ (`beta`)
% weights their frequency deviations.
%
% <@Examples>
% Control the generators at buses 1 and 2 and simulate a fault:
%
% ```matlab
% net = network.IEEE9bus();
% g1  = net.a_Bus{1}.a_Component{1};
% g2  = net.a_Bus{2}.a_Component{1};
% agc = net.add_global_controller("agc-PI", {g1, g2}, parameter=struct(kP=100, kI=500));
% net.initialize;
% sc  = net.add_scenario("fault");
% sc.add_fault("B007", [1,1.05]);
% sol = net.simulate("fault");
% ```
%
% See also GlobalController, PowerNetwork.add_global_controller

    properties (Constant, Hidden) % Model definition
        key = "agc-PI"                        % Model key that selects this class in `PowerNetwork.add_global_controller`.
        s_role = "agc"                        % Role of the controller (automatic generation control).
        sv_x = "xi"                           % Names of the states.
        sv_u = "omega"                        % Names of the inputs, one per controlled generator.
        sv_y = "Pmech"                        % Names of the outputs, one per controlled generator.
        sv_para = ["alpha","beta","kP","kI"]  % Names of the dynamic parameters passed to the model functions.
    end           
    
    methods (Access={?PowerNetwork})
        function obj = broadcast_PI_AGC(net, tag, varargin, opt)
        % Create the AGC with the tag net tag + "AGC" + tag for the generators given after the tag.
            arguments (Input)
                net % PowerNetwork that contains the controlled generators.
                tag % Number of the tag; the controller tag is the network tag + "AGC" + tag.
            end
            arguments (Input, Repeating)
                varargin % Controlled generators, each a generator object or its tag.
            end
            arguments (Input)
                opt.alpha (:,1) double = 1 % [pu] Share of the command for each controlled generator; a scalar applies to all.
                opt.beta  (:,1) double = 1 % [pu] Weight of each generator's frequency deviation; a scalar applies to all.
                opt.kP    (1,1) double = 100 % [pu] Proportional gain.
                opt.kI    (1,1) double = 500 % [1/s] Integral gain.
            end 
            arguments (Output)
                obj % broadcast_PI_AGC object.
            end
            obj@GlobalController(net, "AGC"+tag, varargin{:})            

            % A scalar alpha or beta (e.g. the default) applies to every controlled unit
            nCU = max(numel(obj.controlledUnits), 1);
            if isscalar(opt.alpha); opt.alpha = repmat(opt.alpha, [nCU,1]); end
            if isscalar(opt.beta);  opt.beta  = repmat(opt.beta,  [nCU,1]); end

            na = numel(opt.alpha);
            nb = numel(opt.beta);
            if na ~= nCU || nb ~= nCU
                error(msg("GUILDA:broadcast_PI_AGC:InvalidSize", string(nCU)))
            end            

            obj.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", obj.a_Parameter)} = Parameter(obj, "dynamics", struct( ...
                "alpha", opt.alpha, ...
                 "beta", opt.beta, ...
                   "kP", repmat(opt.kP, [na,1]), ...
                   "kI", repmat(opt.kI, [na,1])));
        end
    end
    
    methods (Static)
        dx = fcn_dx(t, x, V, u, param, omega0)
        y  = fcn_y(t, x, V, u, param, omega0)
        M  = fcn_Mass(t, x, V, u, param, omega0)
        [Axx,Bxv,Bxu] = Jacobi_dx(t,x,V,u,param,omega0);
        [Cyx,Dyv,Dyu] = Jacobi_Y(t,x,V,u,param,omega0);
    end
end
