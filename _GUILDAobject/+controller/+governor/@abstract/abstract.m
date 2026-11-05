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
    properties (SetAccess=protected, Hidden) % Model definition
        key = "governor"  % Kind of controller ("governor": beside the AVR).
        sv_x  % Names of the states (set by the concrete governors).
        sv_u = ["omega";"Pref";"Plimit"]  % Names of the inputs: speed deviation, load setting and load limiter.
        sv_y = "Pmech"  % Names of the outputs: mechanical power of the generator.
        sv_para  % Names of the dynamic parameters (set by the concrete governors).
    end
    methods
        function obj = abstract(tag)
        % Create the governor base object with the tag "CG" + tag.
            arguments (Input)
                tag (1,1) string = "base" % Tag suffix; the controller tag is "CG" + tag.
            end
            arguments (Output)
                obj % Governor object.
            end
            obj@LocalController("CG"+tag)
        end
    end

    methods (Access=protected)
        r_P0 = initial_output(obj, u)
    end

    methods (Static, Hidden)
        [r_Pref, r_Plimit] = load_setting(r_pos0, r_PLM, r_gain, r_posMax)
        [r_gate, l_ref] = lvg(r_e, r_Plimit)
        [r_rate, r_slope] = servo_rate(r_err, r_pos, r_gain, r_rateMin, r_rateMax, r_posMin, r_posMax)
    end
end
