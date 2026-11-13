classdef T < Branch
% Transmission line modeled as a T circuit with the shunt capacitance at the midpoint.
% The series impedance `R + 1j*X` is split into two halves and the shunt
% admittance `1j*C` sits between them, so `C` is the total line charging.
% All values are in per unit on the network base.
%
% R, X and C are the values of all circuits together (tab_parameter.dynamics.circuit,
% default 2). get_admittance_matrix(Status=, Point=) also gives the line with one or all
% circuits grounded ("3LG", "6LG" at Point from the from end, 0 < Point < 1) or open
% ("3open", "6open"); see Branch.
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
        key = "T"      % Type name used by PowerNetwork.add_branch.
    end

    methods (Access={?PowerNetwork})
        function obj = T(index, opt)
            % Create the branch; called through `PowerNetwork.add_branch`.
            arguments (Input)
                index (1,1) string   % Number part of the tag, e.g. "001".
                opt   (1,1) struct   % Branch settings of add_branch.
            end
            arguments (Output)
                obj   % New branch object.
            end
            obj@Branch(index, opt)
        end
    end

end
