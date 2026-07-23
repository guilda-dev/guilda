classdef pi < Branch

    properties(Constant)  
        header = "EL"
        key    = "pi"
    end

    methods
        function Ymat = get_admittance_matrix(obj)
            para  = obj.para_dynamics;
            yij   = 1/(para.R+1j*para.X);
            cij   = 1j * para.C;
            Ymat  = [ cij+yij,    -yij ;
                         -yij, cij+yij ];
        end
    end
end