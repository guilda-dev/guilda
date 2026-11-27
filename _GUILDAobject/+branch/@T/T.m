classdef T < Branch
% Transmission line modeled as a T circuit with the shunt capacitance at the midpoint.
% The series impedance `R + 1j*X` is split into two halves and the shunt
% admittance `1j*C` sits between them, so `C` is the total line charging.
% All values are in per unit on the network base.
%
% A line has no transformer, so tab_parameter.dynamics.tap and .phase are NaN. Tap and
% Phase of add_branch are ignored (with a warning unless Tap is 0 or 1 and Phase is 0); use
% branch.pi_transformer for an off-nominal tap or a phase shift.
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
% **Parameters** (the columns of `tab_parameter.dynamics`)
% - `R` [pu]: Series resistance of all circuits together.
% - `X` [pu]: Series reactance of all circuits together.
% - `C` [pu]: Shunt susceptance at the midpoint of all circuits together (the total line charging).
% - `tap` [pu]: NaN (a line has no transformer).
% - `phase` [rad]: NaN (a line has no transformer).
% - `circuit`: Number of parallel circuits (default 2).
%
% **Equations** ($V_\mathrm{from}$ and $V_\mathrm{to}$ are the complex voltages of the from and to
% buses, $I_\mathrm{from}$ and $I_\mathrm{to}$ the complex currents injected into the branch at those
% ends; state "close", the other states are in `get_admittance_matrix`)
% ```math
% \begin{bmatrix} I_\mathrm{from} \\ I_\mathrm{to} \end{bmatrix}
% = \frac{1}{2Y + jC}\begin{bmatrix} Y(Y + jC) & -Y^2 \\ -Y^2 & Y(Y + jC) \end{bmatrix}
% \begin{bmatrix} V_\mathrm{from} \\ V_\mathrm{to} \end{bmatrix}, \quad
% Y = \frac{2}{R + jX}
% ```
% (the midpoint node eliminated; $Y$ is the admittance of each half of the series impedance).
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
                index (1,1) string  % Number part of the tag, e.g. "001".
                opt   (1,1) struct  % Branch settings of add_branch.
            end
            arguments (Output)
                obj  % New branch object.
            end
            % A line has no transformer: tap and phase are NaN. Tap 0 or 1 and Phase 0 (the
            % add_branch defaults; tap 0 is "none" in MATPOWER) or NaN pass silently; other
            % values are ignored with a warning.
            l_ignored = ~(isnan(opt.Tap) || opt.Tap == 0 || opt.Tap == 1) || ~(isnan(opt.Phase) || opt.Phase == 0);
            r_tap     = opt.Tap;
            r_phase   = opt.Phase;
            opt.Tap   = NaN;
            opt.Phase = NaN;
            obj@Branch(index, opt)
            if l_ignored
                show_msg("warning", "GUILDA:Branch:LineTapIgnored", char(obj.s_tag), char(obj.key), r_tap, r_phase)
            end
        end
    end

end
