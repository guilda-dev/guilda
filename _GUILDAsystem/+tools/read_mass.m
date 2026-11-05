function M = read_mass(model)
% Read the constant mass matrix of a component or a controller.
%
% simulate has no point at which to evaluate fcn_Mass, so it calls f_Mass with empty t, x,
% V, I and u. A mass matrix that needs them stops with GUILDA:read_mass:NotConstant.
    arguments (Input)
        model % Component, LocalController or GlobalController with f_Mass.
    end
    arguments (Output)
        M % Mass matrix, one row and column per state.
    end
    nx = numel(model.sv_x);
    try
        M = model.f_Mass([],[],[],[],[]);
    catch ME
        throw_not_constant(model, nx, ME.message);
    end
    if ~isequal(size(M),[nx,nx]) && ~(nx == 0 && isempty(M))
        throw_not_constant(model, nx, "size " + join(string(size(M)),"x"));
    end
end

function throw_not_constant(model, nx, s_detail)
    error(msg("GUILDA:read_mass:NotConstant", model.s_tag, string(nx), string(nx), s_detail));
end
