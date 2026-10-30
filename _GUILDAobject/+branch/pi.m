classdef pi < Branch
% Transmission line modeled as a pi circuit with shunt capacitance at both ends.
% The series impedance is `R + 1j*X` and each end has a shunt admittance
% `1j*C`, so `C` is half of the total line charging (`C = b/2`).
% All values are in per unit on the network base.
%
% ```
%  ---+---[R + jX]---+---
%     |              |
%   [jC]           [jC]
%     |              |
%  ---+--------------+---
% ```
%
% <@Examples>
% Add a line between buses 1 and 2 of a network:
%
% ```matlab
% net = PowerNetwork();
% net.add_bus();
% net.add_bus();
% br =net.add_branch("pi", [1,2], "R",0.01, "X",0.085, "C",0.0088);
% Y  = br.get_admittance_matrix();
% ```
%
% See also branch.pi_transformer, branch.T, PowerNetwork.add_branch

    properties(Constant) % Identification
        header = "EL"   % Tag prefix of this branch type ("EL" for lines).
        key    = "pi"   % Type name used by PowerNetwork.add_branch.
    end

    methods
        function Ymat = get_admittance_matrix(obj)
        % Return the 2-by-2 admittance matrix of the line.
        % Rows and columns are ordered (from bus, to bus).
            arguments (Output)
                Ymat % [pu] 2-by-2 complex admittance matrix.
            end
            para  = obj.para_dynamics;
            yij   = 1/(para.R+1j*para.X);
            cij   = 1j * para.C;
            Ymat  = [ cij+yij,    -yij ;
                         -yij, cij+yij ];
        end
    end
end
