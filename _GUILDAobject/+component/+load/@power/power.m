classdef power < component.load.abstract
% Constant-power load model.
%
% The load injects the power `Pload + jQload` into the bus whatever the voltage.
% The steady inputs come from the power-flow solution (`get_equilibrium`).
%
% **Dynamic model**
% The model is a dynamical system with state $x$, input $u$ and output $y$, connected
% to its bus through the bus voltage $V$ and the current $I$ it injects.
%
% **State variables** $x$ (`sv_x`)
% - none
%
% **Input signals** $u$ (`sv_u`; the ports driven by local controllers and events)
% - `Pload` [pu]: active power injected into the bus (negative for consumption).
% - `Qload` [pu]: reactive power injected into the bus (negative for consumption).
%
% **Output signals** $y$ (`sv_y`; read by local controllers)
% - none
%
% **Parameters** (`sv_para`)
% - none
%
% **Equation**
% ```math
% I = \overline{\left(\frac{P_\mathrm{load} + jQ_\mathrm{load}}{V}\right)}
% ```
%
% <@Citations>
% - 石崎孝幸 編著, 川口貴弘, 河辺賢一 著, 『電力系統のシステム制御工学
%   ―システム数理とMATLABシミュレーション―』 (計測・制御セレクションシリーズ 4),
%   計測自動制御学会 編, コロナ社, 2022, Sect. 2.4.1, ISBN 978-4-339-03384-7,
%   [publisher page](https://www.coronasha.co.jp/np/isbn/9784339033847/).
% - F. Milano, *Power System Modelling and Scripting* (Power Systems). Berlin Heidelberg,
%   Germany: Springer, 2010, Sect. 10.3.1, pp. 257–259, doi:
%   [10.1007/978-3-642-13669-6](https://doi.org/10.1007/978-3-642-13669-6).
%
% <@Examples>
% ```matlab
% net = PowerNetwork();
% bus = net.add_bus();
% ld  = bus.add_component("load-power", "P", -0.8, "Q", -0.3);
% ld.s_tag                          % "B001LPQ1"
% ld.sv_u                           % Pload, Qload
% ```
%
% See also component.load.abstract, component.load.impedance, Bus.add_component
    
    properties(Constant) % Model definition
        key = "load-power";        % Model key that selects this class in `Bus.add_component`.
        sv_x = [];                 % State names (none).
        sv_u = ["Pload","Qload"];  % Input port names.
        sv_y = [];                 % Output names (none).
        sv_para = [];              % Dynamic parameter names (none).
        Prefix = "LP";             % Short name of the model (the tag starts with "LPQ").
    end

    methods(Access={?Bus})
        function obj = power(index, ~, varargin)
            % Create the load; called through `Bus.add_component`.
            %
            % `index` is the tag suffix (the tag is the bus tag + `"LPQ"+index`). The
            % `parameter` argument is ignored, and `varargin` holds the
            % name-value options of `add_component`.
            arguments (Input)
                index  % Number of the tag.
                ~      % Parameter input of Bus.add_component (ignored).
            end
            arguments (Input, Repeating)
                varargin  % Options of Bus.add_component, passed on to Component.
            end
            arguments (Output)
                obj  % Constant-power load object.
            end
            obj@component.load.abstract("PQ"+index, varargin{:})
        end
    end
    
    methods
        [rv_Xequilibrium, rv_Uequilibrium]  = get_equilibrium(obj, c_V, c_I, r_P, r_Q);    
        sct_hessian = get_hessian(obj, x, V, u)
    end

    methods
        dx = fcn_dx(obj, t, x, V, u, param, omega0);
        I  = fcn_I(obj, t, x, V, u, param, omega0);
        y  = fcn_Y(obj, t, x, V, param, omega0);
        M  = fcn_Mass(obj, t, x, V, u, param, omega0);
    end

    methods (Static)        
        [Axx,Bxv,Bxu] = Jacobi_dx(t,x,V,u,param,omega0);
        [Cyx,Dyv] = Jacobi_Y(t,x,V,param,omega0);
        [Cix,Div,Diu] = Jacobi_I(t,x,V,u,param,omega0);
    end
end
