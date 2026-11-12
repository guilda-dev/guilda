classdef two_winding_transformer < Branch
% Two-winding transformer with an off-nominal tap ratio and a phase shift.
% The series impedance is `R + 1j*X`, the shunt admittance `1j*C` is at the
% from end, `tap` [pu] is the voltage magnitude ratio and `phase` [rad] the
% phase shift (set with "Tap" and "Phase" in PowerNetwork.add_branch).
% Other values are in per unit on the network base.
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
