function Ymat = get_admittance_matrix(obj)
% Return the 2-by-2 admittance matrix of the transformer.
% Rows and columns are ordered (from bus, to bus).
    arguments (Input)
        obj
    end
    arguments (Output)
        Ymat % [pu] 2-by-2 complex admittance matrix.
    end
    para  = obj.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", obj.a_Parameter)};
    yij   = 1/(para.R+1j*para.X);
    cij   = 1j * para.C;
    tap   = para.tap;
    phase = para.phase;

    ym = [cij+yij/tap^2, -yij/tap;
               -yij/tap,     yij];

    em = blkdiag(1, exp(1j*phase));

    Ymat = ym*em;
end
