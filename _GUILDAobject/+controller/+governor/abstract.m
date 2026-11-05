classdef abstract < LocalController
% Base class of the governors (speed governor and turbine) attached to a generator.
% A governor is attached to the generator beside its AVR (key "governor"). It
% observes the speed deviation `omega` [pu] of the generator and takes the input
% signals `u = [omega; Pref; Plimit]`: `Pref` is the load setting (65M) and `Plimit` the
% load limiter (77M), in pu of the rated MW of the machine. They match no output
% of the generator, so they stay at their equilibrium. Its output signal `Pmech` [pu on
% the system base] is the mechanical power input of the generator.
%
% `Prate` [pu] is the rated MW of the machine divided by the system base, so that
% `Pmech = Prate*Pt` for the turbine output `Pt` [pu of the rated MW]. `PLM` [%]
% is the governor margin of the report (the Y-method data):
%
% - `PLM > 0` (governor-free operation): `Pref` = the initial output, and
%   `Plimit = Pref + PLM/100`
% - `PLM = 0`: `Plimit` is the upper limit of the servo position, so the
%   output can rise up to that limit
% - `PLM < 0` (load-limit operation): `Pref` = the initial output + `|PLM|/100`,
%   and `Plimit` = the initial output, so the output does not rise when the
%   frequency drops
%
% The values are in units of the servo position, which equals the turbine output
% at a steady state when the gains of the turbine sum to 1 (as in the report).
% A governor that does not move ("locked", e.g. a pumping machine in the report) is
% simply no governor: the generator then keeps `Pmech` at its equilibrium.
%
% See also controller.governor.IEEJ_LPT1, controller.governor.IEEJ_LPT3, controller.governor.IEEJ_LPT4, Component.add_local_controller
    properties (SetAccess=protected, Hidden)
        key  = "governor"
        sv_x
        sv_u = ["omega";"Pref";"Plimit"]
        sv_y = "Pmech"
        sv_para
    end
    methods
        function obj = abstract(tag)
        % Create the governor base object with the tag "CG" + tag.
            arguments
                tag (1,1) string = "base" % Tag suffix; the controller tag is "CG" + tag.
            end
            arguments (Output)
                obj % Governor object.
            end
            obj@LocalController("CG"+tag)
        end
    end

    methods (Access=protected)
        function r_P0 = initial_output(obj, u)
        % Turbine output at the equilibrium [pu of the rated MW]: Pmech / Prate.
        %
        % Inputs:
        % - `u` [pu] Equilibrium input of the generator (Pmech is read by name).
            comp = obj.a_Component;
            r_Pmech = u(1);
            if isa(comp, "Component") && any(comp.sv_u == "Pmech")
                r_Pmech = u(comp.sv_u == "Pmech");
            end
            r_P0 = r_Pmech / obj.tab_parameter.dynamics{:, 'Prate'};
        end
    end

    methods (Static, Hidden)
        function [r_Pref, r_Plimit] = load_setting(r_pos0, r_PLM, r_gain, r_posMax)
        % Load setting (65M) and load limiter (77M) from the margin PLM [%].
        %
        % Inputs:
        % - `r_pos0` Servo position at the equilibrium.
        % - `r_PLM` [%] Governor margin (of the rated MW).
        % - `r_gain` Steady-state gain from the servo position to the turbine output.
        % - `r_posMax` Upper limit of the servo position.
            r_margin = abs(r_PLM)/100/r_gain;
            if r_PLM > 0
                r_Pref   = r_pos0;
                r_Plimit = r_pos0 + r_margin;
            elseif r_PLM == 0
                r_Pref   = r_pos0;
                r_Plimit = r_posMax;
            else
                r_Pref   = r_pos0 + r_margin;
                r_Plimit = r_pos0;
            end
        end

        function [r_gate, l_ref] = lvg(r_e, r_Plimit)
        % Low value gate: the smaller of the load setting signal r_e and the limiter.
        % l_ref is true when r_e passes (also when they are equal).
            l_ref = r_e <= r_Plimit;
            if l_ref
                r_gate = r_e;
            else
                r_gate = r_Plimit;
            end
        end

        function [r_rate, r_slope] = servo_rate(r_err, r_pos, r_gain, r_rateMin, r_rateMax, r_posMin, r_posMax)
        % Speed of the servo position: r_gain*r_err limited to [r_rateMin, r_rateMax],
        % and 0 while the position is at a limit and pushed further out (non-windup).
        % r_slope is d(r_rate)/d(r_err) on the active branch.
            r_rate  = r_gain*r_err;
            r_slope = r_gain;
            if r_rate > r_rateMax
                r_rate = r_rateMax;  r_slope = 0;
            elseif r_rate < r_rateMin
                r_rate = r_rateMin;  r_slope = 0;
            end
            if (r_pos >= r_posMax && r_rate > 0) || (r_pos <= r_posMin && r_rate < 0)
                r_rate = 0;  r_slope = 0;
            end
        end
    end
end
