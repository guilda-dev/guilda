classdef two_winding_transformer < Branch
% Two-winding transformer with an off-nominal tap ratio and a phase shift.
% The series impedance is `R + 1j*X`, the shunt admittance `1j*C` is at the
% from end, `tap` [pu] is the voltage magnitude ratio and `phase` [rad] the
% phase shift (set with "Tap" and "Phase" in PowerNetwork.add_branch).
% Other values are in per unit on the network base.
%
% R, X and C are the values of all circuits together (tab_parameter.dynamics.circuit,
% default 2). get_admittance_matrix(Status=, Point=) also gives the branch with one or all
% circuits grounded ("3LG", "6LG") or open ("3open", "6open"); see Branch. The ideal
% transformer is taken to be at the from end, and Point (0 < Point < 1) is the fault
% position on the series impedance after it. Common simulators place a transformer fault
% on a terminal bus and only open a transformer; GUILDA also accepts the fault states.
%
% <@Examples>
% Add a transformer with tap 0.969 between buses 1 and 2 of a network:
%
% ```matlab
% net = PowerNetwork();
% net.add_bus();
% net.add_bus();
% br = net.add_branch("two_winding_transformer", [1,2], "X",0.5562, "Tap",0.969);
% Y  = br.get_admittance_matrix();
% ```
%
% See also branch.pi_transformer, PowerNetwork.add_branch

    properties(Constant) % Identification
        header = "ET"                    % Tag prefix of this branch type ("ET" for transformers).
        key = "two_winding_transformer"  % Type name used by PowerNetwork.add_branch.
    end

    methods (Access={?PowerNetwork})
        function obj = two_winding_transformer(index, opt)
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
