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
        header = "ET"                        % Tag prefix of this branch type ("ET" for transformers).
        key    = "two_winding_transformer"   % Type name used by PowerNetwork.add_branch.
    end

    methods
        function Ymat = get_admittance_matrix(obj)
        % Return the 2-by-2 admittance matrix of the transformer.
        % Rows and columns are ordered (from bus, to bus).
            arguments (Output)
                Ymat % [pu] 2-by-2 complex admittance matrix.
            end
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