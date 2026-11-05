function Ymat = get_admittance_matrix(obj)
% Return the 2-by-2 admittance matrix of the line.
% Rows and columns are ordered (from bus, to bus). The midpoint node
% is eliminated (Kron reduction).
    arguments (Input)
        obj
    end
    arguments (Output)
        Ymat % [pu] 2-by-2 complex admittance matrix.
    end
    para  = obj.para_dynamics;
    yij   = 1/(para.R+1j*para.X);
    cij   = 1j * para.C;

    Y = 2 * yij;
    b = cij;

    Ymat = [ Y*(Y+b),    -Y^2 ;
                -Y^2, (Y+b)*Y ] /(Y+b+Y);
end
