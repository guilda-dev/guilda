function params = Vconstant(omega0)
    if nargin==0
        omega0 = 2*pi*60;
    end

    Vr = 480;
    vdc_st = 2.44 * 1e+3 / Vr;

    params = table(vdc_st);
end    