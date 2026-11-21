classdef (Sealed = true) Static < LocalController
% Static AVR: the default AVR of a synchronous generator, which keeps the field voltage at its reference.
% Every synchronous generator (`component.generator.*`) gets one at creation, so that its
% AVR slot is always filled. It has no state and passes its inputs through:
% `Vfield = Vfd_ref + Vpss`. `Vfd_ref` matches no output of the generator, so it stays at its
% equilibrium, which `get_equilibrium` sets to the equilibrium `Vfield` of the generator.
% `Vpss` is the output of a PSS attached under it (0 at the equilibrium, and 0 without a PSS).
% Without a PSS the generator therefore behaves as without an AVR, with its `Vfield` input
% at its equilibrium; with a PSS (e.g. `add_local_controller("pss-PSS1")`) the PSS output
% adds to the field voltage directly.
%
% Attaching another AVR (e.g. `gen.set_avr("avr-ST1")` or
% `add_local_controller("avr-ST1")`) replaces it without a warning. Tripping it in a scenario makes
% the `Vfield` input of the generator take its equilibrium value, which is the
% value that the controller gives, so the result is the same as not tripping it. An input event or
% a global controller on `Vfield` adds to its output, as on a generator without an AVR.
% The built-in networks keep it on every synchronous generator with `LocalController=false`
% (their default), which adds none of the controllers of `local_controller/`.
%
% **Dynamic model**
% No state.
%
% **Input signals** $u$ (`sv_u`)
% - `Vfd_ref` [pu] Reference of the field voltage (kept at its equilibrium).
% - `Vpss` [pu] Output of the PSS under it (0 without a PSS).
%
% **Output signals** $y$ (`sv_y`)
% - `Vfield` [pu] Field voltage, the `Vfield` input of the generator.
%
% **Equations**
% ```math
% V_\mathrm{field} = V_\mathrm{fd,ref} + V_\mathrm{pss}
% ```
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% gen = net.a_Bus{1}.a_Component{1};
% gen.avr    % the Static AVR ("avr-static")
% gen.add_local_controller("avr-ST1");    % replaces it
% ```
%
% See also controller.governor.Static, controller.avr.AVR_ST1, Component.add_local_controller

    properties (Constant, Hidden) % Model definition
        key    = "avr-static"  % Model key that selects this class in `Component.add_local_controller`.
        s_role = "avr"  % Role in Component.add_local_controller ("avr": on the component, in the AVR slot).
    end
    properties (SetAccess=protected, Hidden) % Model definition
        sv_x    = strings(0,1)  % Names of the states: none.
        sv_u    = ["Vfd_ref"; "Vpss"]  % Names of the inputs: the reference of the output and the PSS output.
        sv_y    = "Vfield"  % Names of the outputs: the input of the generator.
        sv_para = strings(0,1)  % Names of the dynamic parameters: none.
    end

    methods (Access={?Component})
        function obj = Static(tag)
        % Create a Static AVR with the tag "CA" + tag.
            arguments (Input)
                tag (1,1) string  % Tag suffix; the controller tag is "CA" + tag.
            end
            arguments (Output)
                obj  % Static object.
            end
            obj@LocalController("CA"+tag)
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
