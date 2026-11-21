function sct_hessian = get_hessian(obj, x, V, u)
% Return the Hessian of the energy function of the component at a point (port "PI").
%
% The energy-function form of the linear model of the component. With the deviations x
% of the states and v = [theta; V] of its bus voltage (angle and magnitude; port "PI"),
%   dx/dt = -R (Hxx x + Hxv v)      (state equation)
%   w_dev =     Hvx x + Hvv v       (contribution to the bus balance w)
% where w_dev = dU/dv = -[P; Q/V] is the gradient of the energy function U of the
% component with respect to v, with P and Q the power the component supplies to the bus
% (positive into the bus). The bus balance is the sum of w_dev over the components and
% the network at the bus (the sign of the energy-function papers: a constant-power load
% has U = -P theta - Q log V). For a component with an energy function, Hxx = d2U/dx2,
% Hxv = d2U/dx dv, Hvv = d2U/dv2, Hvx = Hxv.' and Hxx, Hvv are symmetric; R is constant
% (it includes the inverse of the mass matrix fcn_Mass). A lossy part, such as the
% conductance of an impedance load, has no energy function: Hvx and Hvv are then the
% Jacobian of the port balance w_dev, which is not symmetric.
%
% The blocks are exact at any point, not only at the equilibrium: -R [Hxx Hxv] is the
% Jacobian of the state equation and [Hvx Hvv] the Jacobian of w_dev with respect to
% [x; theta; V] (the same model as get_linear_matrix). The inputs u are constants of
% the point; their Jacobians are not part of this form.
%
% This base method stops with GUILDA:Component:HessianNotSupported, which names the
% class: a class supports the form by overriding get_hessian (a method in its @Class
% folder, with the signature in its classdef). Implemented by the synchronous
% generators (classical, one_axis, two_axis, park), the loads (impedance, power, current, ZIP)
% and the inverters (GFMInverter.VSG_classical, GFLInverter.Static).
%
% Returned struct (n_x states):
%   Hxx (n_x x n_x), Hxv (n_x x 2), Hvx (2 x n_x), Hvv (2 x 2), R (n_x x n_x),
%   StateName (n_x x 1 string): the state labels of the variable map,
%   PortName (2 x 1 string): theta and V of the bus, with the bus tag as the labels Vre,
%   Vim of the variable map.
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();  net.initialize();
% H = net.a_Bus{1}.a_Component{1}.get_hessian();
% eig(-H.R*H.Hxx)                   % with the bus voltage held fixed
% ```
%
% See also get_linear_matrix, PowerSystemModel.get_sys
%
% <@Group> Queries and checks
    arguments (Input)
        obj
        x (:,1) double = obj.rv_Xequilibrium  % States (default: the equilibrium).
        V (:,1) double = [real(obj.c_Vequilibrium); imag(obj.c_Vequilibrium)]  % [pu] Bus voltage [Vre; Vim] (default: the equilibrium).
        u (:,1) double = obj.rv_Uequilibrium  % Inputs (default: the equilibrium).
    end
    arguments (Output)
        sct_hessian struct  % Fields Hxx, Hxv, Hvx, Hvv, R, StateName, PortName.
    end
    error(msg("GUILDA:Component:HessianNotSupported", class(obj), "the class does not override get_hessian"))
end
