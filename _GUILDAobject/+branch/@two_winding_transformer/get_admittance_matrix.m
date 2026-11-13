function Ymat = get_admittance_matrix(obj, opt)
% Return the 2-by-2 admittance matrix of the transformer in a state.
% Rows and columns are ordered (from bus, to bus).
%
% Status "close" (default) is ym*E with ym = [jC + y/tap^2, -y/tap; -y/tap, y] (y =
% 1/(R+jX), the shunt jC on the bus side of the from end) and E = diag(1, exp(j*phase)).
% With n circuits (tab_parameter.dynamics.circuit), "6open" is the zero matrix and "3open"
% (n-1)/n of the closed matrix. The ideal transformer (tap) stays at the from end and Point
% is the position on the series impedance after it: grounding the fault point at Point = p
% (q = 1-p) gives for all circuits ("6LG") diag(jC + y/(p*tap^2), exp(j*phase)*y/q) (the
% bus-side shunt stays), for one circuit 1/n of it, added to the closed (n-1) circuits for
% "3LG". Point is used only by "3LG" and "6LG"; the other states ignore it. (Common
% simulators place a transformer fault on a terminal bus and only open a transformer.)
%
% <@Examples>
% ```matlab
% Y  = br.get_admittance_matrix();                          % closed
% Yo = br.get_admittance_matrix(Status="6open");            % all circuits open (zeros(2))
% ```
%
% See also Branch, PowerNetwork.get_admittance_matrix
    arguments (Input)
        obj
        opt.Status (1,1) string {mustBeMember(opt.Status, ["close","3LG","6LG","3open","6open"])} = "close"  % State of the branch.
        opt.Point  (1,1) double = NaN   % Fault position on the series impedance after the ideal transformer, from the from end (0) to the to end (1), 0 < Point < 1; used only by "3LG" and "6LG".
    end
    arguments (Output)
        Ymat (2,2) double   % [pu] 2-by-2 complex admittance matrix (from, to).
    end
    para  = obj.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", obj.a_Parameter)}.tab_parameter;
    yij   = 1/(para.R+1j*para.X);
    cij   = 1j * para.C;
    tap   = para.tap;
    phase = para.phase;

    ym = [cij+yij/tap^2, -yij/tap;
               -yij/tap,     yij];

    em = blkdiag(1, exp(1j*phase));

    Ymat = ym*em;
    if opt.Status == "close"
        return
    end

    n = para.circuit;
    if n == 1 && ismember(opt.Status, ["3LG","3open"])
        error(msg("GUILDA:Branch:SingleCircuit", char(obj.s_tag), char(opt.Status)))
    end
    p = opt.Point;
    if ismember(opt.Status, ["3LG","6LG"]) && ~(p > 0 && p < 1)
        error(msg("GUILDA:Branch:InvalidPoint", char(obj.s_tag), char(opt.Status), num2str(p)))
    end
    q = 1 - p;
    switch opt.Status
        case "6open"
            Ymat = zeros(2);
        case "3open"
            Ymat = Ymat*(n-1)/n;
        case "3LG"
            Ymat = Ymat*(n-1)/n + diag([cij + yij/(p*tap^2), exp(1j*phase)*yij/q])/n;
        case "6LG"
            Ymat = diag([cij + yij/(p*tap^2), exp(1j*phase)*yij/q]);
    end
end
