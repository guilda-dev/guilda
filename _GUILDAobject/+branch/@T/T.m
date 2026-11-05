classdef T < Branch
% Transmission line modeled as a T circuit with the shunt capacitance at the midpoint.
% The series impedance `R + 1j*X` is split into two halves and the shunt
% admittance `1j*C` sits between them, so `C` is the total line charging.
% All values are in per unit on the network base.
%
% ```
%  ---[(R+jX)/2]---+---[(R+jX)/2]---
%                  |
%                [jC]
%                  |
%  ----------------+----------------
% ```
%
% <@Examples>
% Add a T-model line between buses 1 and 2 of a network:
%
% ```matlab
% net = PowerNetwork();
% net.add_bus();
% net.add_bus();
% br = net.add_branch("T", [1,2], "R",0.01, "X",0.085, "C",0.0176);
% Y  = br.get_admittance_matrix();
% ```
%
% See also branch.pi, PowerNetwork.add_branch

    properties(Constant) % Identification
        header = "EL"  % Tag prefix of this branch type ("EL" for lines).
        key = "T"  % Type name used by PowerNetwork.add_branch.
    end

end
