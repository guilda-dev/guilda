function [r_Pref, r_Plimit] = load_setting(r_pos0, r_PLM, r_gain, r_posMax)
% Load setting (65M) and load limiter (77M) from the margin PLM [%].
    arguments (Input)
        r_pos0    (1,1) double  % Servo position at the equilibrium.
        r_PLM     (1,1) double  % [%] Governor margin (of the rated MW).
        r_gain    (1,1) double  % Steady-state gain from the servo position to the turbine output.
        r_posMax  (1,1) double  % Upper limit of the servo position.
    end
    arguments (Output)
        r_Pref    % Load setting (65M) at the equilibrium.
        r_Plimit  % Load limiter (77M).
    end
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
