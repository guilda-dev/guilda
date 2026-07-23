classdef two_winding_transformer < Branch

    properties(Constant)     
        header = "ET"
        key    = "two_winding_transformer"
    end
       
    methods
        function Ymat = get_admittance_matrix(obj)
            para  = obj.para_dynamics;
            yij   = 1/(para.R+1j*para.X);
            cij   = 1j * para.C;
            tap   = para.tap;
            phase = para.phase;

            ym = [cij+yij/tap^2, -yij/tap;
                       -yij/tap,     yij];

            em = blkdiag(1, exp(1j*phase));

            Ymat = ym*em;
        end
    end
    
end