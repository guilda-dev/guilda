classdef pi_transformer < Branch
% Pi-circuit line with a phase-shifting transformer at the from end.
% An ideal transformer with complex ratio `tap*exp(1j*phase)` at the from
% bus is followed by a pi line with series impedance `R + 1j*X` and shunt
% admittance `1j*C` at each end. `tap` [pu] is the voltage magnitude ratio
% and `phase` [rad] the phase shift (set with "Tap" and "Phase" in
% PowerNetwork.add_branch). Other values are in per unit on the network base.
%
% ```
%  ---+  +----+--[R + jX]--+---
%     @  @    |            |
%     @  @  [jC]         [jC]
%     @  @    |            |
%  ---+  +----+------------+---
% ```
%
% <@Examples>
% Add a transformer with tap 0.978 between buses 1 and 2 of a network:
%
% ```matlab
% net = PowerNetwork();
% net.add_bus();
% net.add_bus();
% br = net.add_branch("pi_transformer", [1,2], "X",0.2091, "Tap",0.978);
% Y  = br.get_admittance_matrix();
% ```
%
% See also branch.pi, branch.two_winding_transformer, PowerNetwork.add_branch

    properties(Constant) % Identification
        header = "ET"           % Tag prefix of this branch type ("ET" for transformers).
        key = "pi_transformer"  % Type name used by PowerNetwork.add_branch.
    end

    methods (Access={?PowerNetwork})
        function obj = pi_transformer(index, opt)
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
