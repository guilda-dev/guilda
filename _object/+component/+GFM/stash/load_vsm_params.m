function [vsc_params,controller_params,ref_model_params] = load_vsm_params(para)
    %% Network base values
    Sb = 100 * 1e+6;
    Vb = 230 * 1e+3;
    omega_st = 2 * pi * 60;
    
    Ib = Sb / Vb;
    Zb = (Vb^2) / Sb;
    Lb = Zb / omega_st;
    Cb = 1 / (omega_st * Zb);
    
    %% Converter base values
    Sr = 100 * 1e+3;
    Vr = 480;
    
    Ir = Sr / Vr;
    Zr = Vr^2 / Sr;
    Lr = Zr;
    Cr = 1 / Zr;
    
    %% Multiple converter parameters (in network base)
    %
    R_f = 0;
    L_f = 0.367 * 1e-3 / Lr;
    C_f = 191 * 1e-6 / Cr;
    R_g = 0;
    L_g = 0.061 * 1e-2 / Lr * para;
    %}
    vdc_st = 2.44 * 1e+3 / Vr;
    
    %{
    R_f = 0;
    L_f = 1e-10;
    C_f = 1e-10;
    R_g = 0;
    L_g = 0.01 * 1e-5 / Lr;
    %}


    %% AC and DC current and voltage control
    Kp_v = 20;
    Ki_v = 400;
    Kp_i = 2;
    Ki_i = 100;
    %{
    Kp_v = 0;
    Ki_v = 100;
    Kp_i = 0;
    Ki_i = 100;
    %}

    %% Droop control
    Jr = 12.8;
    Dp = 4.3;
    Kp = 0.001;
    Ki = 0.5;
    
    %% Store parameters in tables
    vsc_params = table(L_f, R_f, C_f, R_g, L_g);
    controller_params = table(L_f, C_f, R_f, Kp_v, Ki_v, Kp_i, Ki_i, vdc_st);
    ref_model_params = table(omega_st, Jr, Dp, Kp, Ki);
    
    % clearvars -except vsc_params dc_source_params controller_params ref_model_params 
end