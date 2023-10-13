function params = Delay1order_model(omega0)
    if nargin==0
        omega0 = 2*pi*60;
    end
    
    Sbase = 500 * 1e3;
    Vbase = 230 * 1e3;

    Ibase = Sbase/Vbase;
    Zbase = Vbase / Ibase;
    Ybase = 1/Zbase;
    Cbase = 1 / omega0 / Zbase;

    vdc_st  = 2.44 * 1e3 / Vbase;
    idc_max = 1.2;

    tau_dc  = 50 * 1e-3;  
    Kdc     = 1.6 * 1e3;
    Gdc     = 0.83  / Ybase;
    Cdc     = 0.008 / Cbase;

    params = table(vdc_st,idc_max,tau_dc,Kdc,Gdc,Cdc);
end