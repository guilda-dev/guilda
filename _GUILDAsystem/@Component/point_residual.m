function [rv_dx, rv_I] = point_residual(obj, rv_point)
% Get the equations of the component and its local controllers at a point.
%
% rv_point is in the order of obj.get_variable_map(). The inputs of the component are the
% values of rv_point, and those of the controllers are read as in Component.get_sys.
%
% Outputs:
%
% - `rv_dx` — Right-hand sides of the state equations (component, then controllers).
% - `rv_I` — [pu] Current injected into the bus [Ire; Iim].
%
% See also LTIsolver.solve
    a_LC = all_controllers(obj);
    [x, V, I, u, c_con] = point_values(obj, a_LC, rv_point);
    c_dx = cell(numel(a_LC),1);
    for k = 1:numel(a_LC)
        c_dx{k} = full(reshape(a_LC{k}.f_dx(0, c_con{k}{:}), [], 1));
    end
    rv_dx = [full(reshape(obj.f_dx(0, x, V, I, u), [], 1)); vertcat(zeros(0,1), c_dx{:})];
    rv_I  = I;
end


function list = all_controllers(parent)
    list = cell(0,1);
    for k = 1:numel(parent.a_LocalController)
        con  = parent.a_LocalController{k};
        list = [list; {con}; all_controllers(con)]; %#ok<AGROW>
    end
end
