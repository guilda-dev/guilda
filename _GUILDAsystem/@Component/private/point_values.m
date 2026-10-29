function [x, V, I, u, c_con] = point_values(obj, a_LC, rv_point)
% Values of the component and of its local controllers a_LC (depth first) at a point,
% rv_point in the order of obj.get_variable_map():
%   x, V, u : read from rv_point
%   I       : fcn_I at the point (the equilibrium current is passed for I)
%   c_con{k}: {x, V, I, u} of a_LC{k}; its inputs are the outputs connected to them by
%             name (the component outputs and the outputs of the other controllers),
%             as in the simulation, and the equilibrium inputs for the others
    nx  = numel(obj.sv_x);
    nxc = cellfun(@(c) numel(c.sv_x), a_LC);
    n_x = nx + sum(nxc);
    x = rv_point(1:nx);
    V = rv_point(n_x + (1:2));
    u = rv_point(n_x + 2 + (1:numel(obj.sv_u)));

    I0 = [real(obj.c_Iequilibrium); imag(obj.c_Iequilibrium)];
    if isempty(I0)
        I0 = zeros(2,1);
    end
    I = obj.f_I(0, x, V, I0, u);
    if numel(I) == 1
        I = [real(I); imag(I)];
    end
    I = reshape(I, 2, 1);

    c_x = cell(numel(a_LC),1);
    for k = 1:numel(a_LC)
        c_x{k} = rv_point(nx + sum(nxc(1:k-1)) + (1:nxc(k)));
    end

    % outputs known so far, by name: the component outputs, then the controllers from the
    % deepest one up (a PSS output is an input of the AVR above it)
    sv_y = reshape(string(obj.sv_y), [], 1);
    rv_y = reshape(obj.f_Y(0, x, V, I, u), [], 1);
    c_con = cell(numel(a_LC),1);
    for k = numel(a_LC):-1:1
        con = a_LC{k};
        uc  = reshape(con.rv_Uequilibrium, [], 1);
        sv_u = reshape(string(con.sv_u), [], 1);
        for m = 1:numel(sv_u)
            idx = find(sv_y == sv_u(m), 1, "last");
            if ~isempty(idx)
                uc(m) = rv_y(idx);
            end
        end
        c_con{k} = {c_x{k}, V, I, uc};
        sv_y = [sv_y; reshape(string(con.sv_y), [], 1)]; %#ok<AGROW>
        rv_y = [rv_y; reshape(con.f_Y(0, c_x{k}, V, I, uc), [], 1)]; %#ok<AGROW>
    end
end
