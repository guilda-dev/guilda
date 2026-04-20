function ust = get_uequilibrium(~,c_V,c_I)
    PQload = c_V * conj(c_I);
    ust = [real(PQload); imag(PQload)];
end
