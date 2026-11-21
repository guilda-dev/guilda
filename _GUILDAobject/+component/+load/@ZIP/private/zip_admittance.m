function [rv_c, r_Vlow] = zip_admittance(param)
% Constant-impedance factors [c_P; c_Q] of the ZIP load below both thresholds.
%
% Shared by fcn_I and Jacobi_I. Below r_Vlow = min(VswitchP, VswitchI) every part is constant
% impedance, f = c |V|^2 with c = kZ + kI/VswitchI + kP/VswitchP^2, so the current is
% conj(u.*c)*V. It is the same function as conj(S/V) without the 0/0 at V = 0 (the current
% is 0 there).
    arguments (Input)
        param  double  % Dynamic parameters in the order of sv_para.
    end
    arguments (Output)
        rv_c    (2,1) double  % [c_P; c_Q]: f_P = c_P |V|^2, f_Q = c_Q |V|^2 below r_Vlow.
        r_Vlow  (1,1) double  % [pu] min(VswitchP, VswitchI).
    end
    rm_k   = reshape(param(1:6), 3, 2).';     % rows [kZ kI kP] for P and Q
    rv_c   = rm_k*[1; 1/param(8); 1/param(7)^2];
    r_Vlow = min(param(7), param(8));
end
