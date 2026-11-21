classdef VSG_classical < component.GFMInverter.abstract
% Grid-forming inverter as a virtual synchronous generator of the classical model.
%
% The inverter behaves as the classical generator (`component.generator.classical`): the
% internal angle follows the swing equation and the internal voltage `Vref` sits behind
% the virtual reactances `Xd` and `Xq`. The current of that classical machine is rotated by
% the angle `alpha` before it enters the bus. The swing equation uses the virtual power of
% the classical current before the rotation, $\tilde{P} = \cos\alpha\,P - \sin\alpha\,Q$ with
% $P + jQ$ the power supplied to the bus, as the phase-compensated VSG of Koizumi et al.:
% with `alpha` equal to the impedance angle of lossy lines, the network seen in the
% rotated frame is lossless. With `alpha = 0` the model is the classical generator. The
% inverter internals and the inner control loops are not modeled.
%
% **Dynamic model**
% The model is a dynamical system with state $x$, input $u$ and output $y$, connected
% to its bus through the bus voltage $V$ and the current $I$ it injects.
%
% **State variables** $x$ (`sv_x`)
% - `delta` [rad]: Internal angle in the network reference frame.
% - `omega` [pu]: Internal frequency deviation from the network frequency.
%
% **Input signals** $u$ (`sv_u`; the ports driven by local controllers)
% - `Pref` [pu]: Virtual power reference (the mechanical power of the classical model); at
%   the equilibrium it is $\tilde{P}$, not the bus power $P$ (unless `alpha = 0`).
% - `Vref` [pu]: Internal voltage reference (the field voltage of the classical model).
%
% **Output signals** $y$ (`sv_y`; read by local controllers)
% - `omega` [pu]: Internal frequency deviation from the network frequency.
%
% **Parameters** (`sv_para`, the columns of `tab_parameter.dynamics`)
% - `M` [s]: Virtual inertia constant.
% - `D` [pu]: Damping coefficient.
% - `Xd` [pu]: d-axis virtual reactance.
% - `Xq` [pu]: q-axis virtual reactance.
% - `alpha` [rad]: Rotation of the current injected into the bus.
%
% **Equations** ($\omega_0$ is the network frequency `get_Hz()`; $V_d$, $V_q$ are the bus
% voltage in the internal dq frame, $I_d$, $I_q$ the current of the classical model)
% ```math
% \left\{
% \begin{aligned}
% \dot{\delta} &= 2\pi\omega_0\,\omega \\
% M\dot{\omega} &= -D\,\omega - \tilde{P} + P_\mathrm{ref}
% \end{aligned}
% \right.
% ```
% with
% ```math
% I_d = \frac{V_\mathrm{ref} - V_q}{X_d}, \quad I_q = \frac{V_d}{X_q}, \quad
% I_0 = e^{j\delta}(I_q - jI_d), \quad I = e^{j\alpha} I_0, \quad
% \tilde{P} = \mathrm{Re}\left(V\,\overline{I_0}\right)
% ```
% where $I_0$ is the current of the classical model and $I$ the current injected into the bus.
%
% <@Examples>
% ```matlab
% net = PowerNetwork();
% bus = net.add_bus();
% vsg = bus.add_component("gfm-vsg-classical", "P", 0.5);
% vsg.sv_x                          % delta, omega
% vsg.tab_parameter.dynamics        % M, D, Xd, Xq, alpha
% vsg.tab_parameter.dynamics.alpha = pi/12;
% ```
%
% See also component.GFMInverter.abstract, component.generator.classical, Bus.add_component

    properties (Constant) % Model definition
        key = "gfm-vsg-classical";             % Model key that selects this class in `Bus.add_component`.
        sv_x = ["delta";"omega"];              % State names.
        sv_u = ["Pref";"Vref"];                % Input port names.
        sv_y = "omega";                        % Output names read by local controllers.
        sv_para = ["M","D","Xd","Xq","alpha"]  % Dynamic parameter names.
    end

    methods (Access={?Bus})
        function obj = VSG_classical(index, parameter, varargin)
            % Create the inverter; called through `Bus.add_component` and `Bus.replace_component`.
            arguments (Input)
                index      % Number of the tag: the tag is the bus tag + "GFM" + index.
                parameter  % Dynamic parameters: a table, a name in parameter.csv ("NGT2"), or NaN for its first row.
            end
            arguments (Input, Repeating)
                varargin  % Options of Bus.add_component, passed on to Component.
            end
            arguments (Output)
                obj  % Grid-forming inverter object.
            end
            obj@component.GFMInverter.abstract(index, parameter, varargin{:})
        end
    end

    methods
        [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, c_V, c_I, r_P, r_Q)
        sct_hessian = get_hessian(obj, x, V, u)
    end

    methods
        dx = fcn_dx(obj, t, x, V, u, param, omega0)
        I  = fcn_I(obj, t, x, V, u, param, omega0)
        y  = fcn_Y(obj, t, x, V, param, omega0)
        M  = fcn_Mass(obj, t, x, V, u, param, omega0)
    end

    methods (Static)
        [cv_E, rv_P, rv_Iq, cv_I] = get_spring_node(rm_x, rm_V, rm_I, rm_u, rr_param)
        [Axx,Bxv,Bxu] = Jacobi_dx(t,x,V,u,param,omega0);
        [Cyx,Dyv] = Jacobi_Y(t,x,V,param,omega0);
        [Cix,Div,Diu] = Jacobi_I(t,x,V,u,param,omega0);
    end
end
