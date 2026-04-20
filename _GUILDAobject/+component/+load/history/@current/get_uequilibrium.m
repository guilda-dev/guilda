function ust = get_uequilibrium(~,~,c_I)
    ust = [abs(c_I); angle(c_I)];
end
