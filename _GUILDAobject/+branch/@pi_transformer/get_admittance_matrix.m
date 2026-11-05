function Ymat = get_admittance_matrix(obj)
% Return the 2-by-2 admittance matrix of the transformer branch.
% Rows and columns are ordered (from bus, to bus).
    arguments (Input)
        obj
    end
    arguments (Output)
        Ymat % [pu] 2-by-2 complex admittance matrix.
    end
    para  = obj.para_dynamics;
    yij   = 1/(para.R+1j*para.X);
    cij   = 1j * para.C;
    tap   = para.tap;
    phase = para.phase;

    r    = tap * exp(1j*phase);
    Ymat = [ (cij+yij)/tap^2,  -yij/conj(r) ;
                  -yij/r    ,      cij+yij  ];
end
