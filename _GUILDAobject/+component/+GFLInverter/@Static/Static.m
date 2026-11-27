classdef Static < component.GFLInverter.abstract
% Grid-following inverter that injects constant power.
%
% The inverter injects the power `Pref + jQref` into the bus whatever the voltage, as
% the constant-power load `component.load.power` with the opposite naming of the sign
% (positive for generation). The steady inputs come from the power-flow solution
% (`get_equilibrium`). The inverter internals and the inner control loops are not modeled.
%
% **Dynamic model**
% The model is a dynamical system with state $x$, input $u$ and output $y$, connected
% to its bus through the bus voltage $V$ and the current $I$ it injects.
% The model has no state, no output and no parameter.
%
% **Input signals** $u$ (`sv_u`; the ports driven by local controllers and events)
% - `Pref` [pu]: active power injected into the bus (positive for generation).
% - `Qref` [pu]: reactive power injected into the bus (positive for generation).
%
% **Equations** ($V$ is the complex bus voltage and $I$ the complex current injected into the bus)
% ```math
% I = \overline{\left(\frac{P_\mathrm{ref} + jQ_\mathrm{ref}}{V}\right)}
% ```
%
% <@Examples>
% ```matlab
% net = PowerNetwork();
% bus = net.add_bus();
% gfl = bus.add_component("gfl-static", "P", 0.4, "Q", 0.1);
% gfl.s_tag                         % "B001GFL1"
% gfl.sv_u                          % Pref, Qref
% ```
%
% See also component.GFLInverter.abstract, component.load.power, Bus.add_component

    properties(Constant) % Model definition
        key = "gfl-static";      % Model key that selects this class in `Bus.add_component`.
        sv_x = [];               % State names (none).
        sv_u = ["Pref","Qref"];  % Input port names.
        sv_y = [];               % Output names (none).
        sv_para = [];            % Dynamic parameter names (none).
    end

    methods(Access={?Bus})
        function obj = Static(index, ~, varargin)
            % Create the inverter; called through `Bus.add_component`.
            %
            % `index` is the tag suffix (the tag is the bus tag + `"GFL"+index`). The
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
                obj  % Grid-following inverter object.
            end
            obj@component.GFLInverter.abstract(string(index), varargin{:})
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
