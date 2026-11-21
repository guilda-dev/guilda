function [r_rate, r_slope] = servo_rate(r_err, r_pos, r_gain, r_rateMin, r_rateMax, r_posMin, r_posMax)
% Speed of the servo position: r_gain*r_err limited to [r_rateMin, r_rateMax],
% and 0 while the position is at a limit and pushed further out (non-windup).
% r_slope is d(r_rate)/d(r_err) on the active branch.
    arguments (Input)
        r_err      (1,1) double  % Error of the servo position.
        r_pos      (1,1) double  % Servo position.
        r_gain     (1,1) double  % Servo gain.
        r_rateMin  (1,1) double  % Lower limit of the speed.
        r_rateMax  (1,1) double  % Upper limit of the speed.
        r_posMin   (1,1) double  % Lower limit of the position.
        r_posMax   (1,1) double  % Upper limit of the position.
    end
    arguments (Output)
        r_rate   % Speed of the servo position.
        r_slope  % Derivative of r_rate with respect to r_err on the active branch.
    end
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
