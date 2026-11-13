function Ymat = get_admittance_matrix(obj, opt)
% Return the 2-by-2 admittance matrix of the line in a state.
% Rows and columns are ordered (from bus, to bus).
%
% Status "close" (default) is the pi circuit [jC+y, -y; -y, jC+y], y = 1/(R+jX). With n
% circuits (tab_parameter.dynamics.circuit), "6open" is the zero matrix and "3open"
% (n-1)/n of the closed matrix. A fault at Point = p (q = 1-p) splits the circuit into two
% pi sections of lengths p and q, and grounding the fault point leaves each end with the
% section behind it grounded: all circuits ("6LG") give diag(p*jC + y/p, q*jC + y/q), one
% circuit 1/n of it, added to the closed (n-1) circuits for "3LG". Point is used only by
% "3LG" and "6LG"; the other states ignore it.
%
% <@Examples>
% ```matlab
% Y  = br.get_admittance_matrix();                          % closed
% Yf = br.get_admittance_matrix(Status="3LG", Point=0.3);   % one circuit grounded at 30 %
% ```
%
% See also Branch, PowerNetwork.get_admittance_matrix
    arguments (Input)
        obj
        opt.Status (1,1) string {mustBeMember(opt.Status, ["close","3LG","6LG","3open","6open"])} = "close"  % State of the branch.
        opt.Point  (1,1) double = NaN   % Fault position from the from end (0) to the to end (1), 0 < Point < 1; used only by "3LG" and "6LG".
    end
    arguments (Output)
        Ymat (2,2) double   % [pu] 2-by-2 complex admittance matrix (from, to).
    end
    para  = obj.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", obj.a_Parameter)}.tab_parameter;
    yij   = 1/(para.R+1j*para.X);
    cij   = 1j * para.C;
    Ymat  = [ cij+yij,    -yij ;
                 -yij, cij+yij ];
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
            Ymat = Ymat*(n-1)/n + diag([p*cij + yij/p, q*cij + yij/q])/n;
        case "6LG"
            Ymat = diag([p*cij + yij/p, q*cij + yij/q]);
    end
end
