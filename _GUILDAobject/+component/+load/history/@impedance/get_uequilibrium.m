function ust = get_uequilibrium(~,c_V,c_I)
    Yload = c_I/c_V;
    ust = [real(Yload); imag(Yload)];
end
