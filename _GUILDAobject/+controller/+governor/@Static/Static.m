classdef (Sealed = true) Static < LocalController
% Static governor: the default governor of a synchronous generator, which keeps the mechanical power at its reference.
% Every synchronous generator (`component.generator.*`) gets one at creation, so that its
% governor slot is always filled. It has no state and passes its input through:
% `Pmech = Pmech_ref`. `Pmech_ref` matches no output of the generator, so it stays at its
% equilibrium, which `get_equilibrium` sets to the equilibrium `Pmech` of the generator.
% The generator therefore behaves as without a governor, with its `Pmech` input at its equilibrium.
%
% Attaching another governor (e.g. `gen.set_governor("gov-LPT1")` or
% `add_local_controller("gov-LPT1")`) replaces it without a warning. Tripping it in a scenario makes
% the `Pmech` input of the generator take its equilibrium value, which is the
% value that the controller gives, so the result is the same as not tripping it. An input event or
% a global controller on `Pmech` adds to its output, as on a generator without a governor.
% The built-in networks keep it on every synchronous generator with `LocalController=false`
% (their default), which adds none of the controllers of `local_controller/`.
%
% **Dynamic model**
% No state.
%
% **Input signals** $u$ (`sv_u`)
% - `Pmech_ref` [pu] Reference of the mechanical power (kept at its equilibrium).
%
% **Output signals** $y$ (`sv_y`)
% - `Pmech` [pu] Mechanical power, the `Pmech` input of the generator.
%
% **Equations**
% ```math
% Pmech = Pmech\_ref
% ```
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% gen = net.a_Bus{1}.a_Component{1};
% gen.governor    % the Static governor ("gov-static")
% gen.add_local_controller("gov-LPT1");    % replaces it
% ```
%
% See also controller.avr.Static, controller.governor.IEEJ_LPT1, Component.add_local_controller

    properties (Constant, Hidden) % Model definition
        key    = "gov-static"  % Model key that selects this class in `Component.add_local_controller`.
        s_role = "governor"  % Role in Component.add_local_controller ("governor": beside the AVR).
    end
    properties (SetAccess=protected, Hidden) % Model definition
        sv_x    = strings(0,1)  % Names of the states: none.
        sv_u    = "Pmech_ref"  % Names of the inputs: the reference of the output.
        sv_y    = "Pmech"  % Names of the outputs: the input of the generator.
        sv_para = strings(0,1)  % Names of the dynamic parameters: none.
    end

    methods (Access={?Component})
        function obj = Static(tag)
        % Create a Static governor with the tag "CG" + tag.
            arguments (Input)
                tag (1,1) string  % Tag suffix; the controller tag is "CG" + tag.
            end
            arguments (Output)
                obj  % Static object.
            end
            obj@LocalController("CG"+tag)
        end
    end

    methods
        sct_hessian = get_hessian(obj, x, V, u)
    end

    methods (Static)
        dx   = fcn_dx(t, x, V, u, param, omega0)
        y    = fcn_y(t, x, V, u, param, omega0)
        Mass = fcn_Mass(t, x, V, u, param, omega0)
        [Axx,Bxv,Bxu] = Jacobi_dx(t,x,V,u,param,omega0)
        [Cyx,Dyv,Dyu] = Jacobi_Y(t,x,V,u,param,omega0)
    end
end
