function [rv_f, rv_df] = zip_factor(r_V, param)
% Voltage factors [f_P; f_Q] of the ZIP load and their derivatives with respect to |V|.
%
% Shared by fcn_I, Jacobi_I, getCompPQ, get_equilibrium and get_hessian. With
% g_I(v) = v (v >= VswitchI) or v^2/VswitchI, and g_P(v) = 1 (v >= VswitchP) or
% v^2/VswitchP^2, f = kZ v^2 + kI g_I(v) + kP g_P(v) (see the class description).
    arguments (Input)
        r_V   (1,1) double  % [pu] Bus voltage magnitude |V|.
        param       double  % Dynamic parameters in the order of sv_para.
    end
    arguments (Output)
        rv_f   (2,1) double  % [f_P; f_Q] at r_V.
        rv_df  (2,1) double  % [df_P/d|V|; df_Q/d|V|] at r_V.
    end
    r_Vp = param(7);
    r_Vi = param(8);
    if r_V >= r_Vi
        r_gI = r_V;      r_dgI = 1;
    else
        r_gI = r_V^2/r_Vi;  r_dgI = 2*r_V/r_Vi;
    end
    if r_V >= r_Vp
        r_gP = 1;        r_dgP = 0;
    else
        r_gP = r_V^2/r_Vp^2;  r_dgP = 2*r_V/r_Vp^2;
    end
    rm_k  = reshape(param(1:6), 3, 2).';       % rows [kZ kI kP] for P and Q
    rv_f  = rm_k*[r_V^2; r_gI; r_gP];
    rv_df = rm_k*[2*r_V; r_dgI; r_dgP];
end
