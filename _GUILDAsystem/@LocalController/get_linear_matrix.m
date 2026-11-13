function sct_block = get_linear_matrix(obj, x, V, u)
% Get the linear block of the local controller at a point.
%
% Returns the linear model of the controller at the states x, the voltage V = [Vre; Vim]
% of the bus of its component and the inputs u, as a struct with the fields A, B, C, D, E
% (E dx/dt = A x + B [V; u], y = C x + D [V; u]) and StateName, InputName, OutputName
% (string columns). The names are the Labels of the variable map of the component
% (comp.get_variable_map): the inputs are the voltage of the bus and the inputs (rows
% "uc"), the states are the states and the outputs are the outputs (rows "yc"; "Y_" +
% name for an output with the name of a state).
%
% get_sys connects the blocks (SolverLIN.solve). The Jacobians are those of the
% simulation (f_JacobiDx, f_JacobiY); a model that returns [] for a block gives zeros.
% The model is not changed.
%
% See also PowerSystemModel.get_sys, Component.get_linear_matrix
%
% <@Group> Called by analyses
    arguments (Input)
        obj
        x (:,1) double   % States of the controller.
        V (:,1) double   % [pu] Voltage [Vre; Vim] of the bus of its component.
        u (:,1) double   % Inputs of the controller.
    end
    arguments (Output)
        sct_block struct   % Fields A, B, C, D, E, StateName, InputName, OutputName.
    end
    nx = numel(obj.sv_x);
    nu = numel(obj.sv_u);
    ny = numel(obj.sv_y);

    % Same Jacobian contract as SolverODE: f_JacobiDx/Y(t,x,V,u)
    [Axx,Bxv,Bxu] = obj.f_JacobiDx(0,x,V,u);
    [Cyx,Dyv,Dyu] = obj.f_JacobiY( 0,x,V,u);

    Axx = shape(Axx, nx, nx);  Bxv = shape(Bxv, nx, 2);  Bxu = shape(Bxu, nx, nu);
    Cyx = shape(Cyx, ny, nx);  Dyv = shape(Dyv, ny, 2);  Dyu = shape(Dyu, ny, nu);

    sv_y = reshape(string(obj.sv_y), [], 1);
    lv_yx = ismember(sv_y, obj.sv_x);
    sv_y(lv_yx) = "Y_" + sv_y(lv_yx);
    comp = obj.observed_component();
    sv_V = ["Vre";"Vim"];
    if ~isempty(comp) && ~isempty(comp.a_Bus)
        sv_V = comp.a_Bus.attach_tag(sv_V);
    end
    sct_block = struct("A", Axx, "B", [Bxv, Bxu], "C", Cyx, "D", [Dyv, Dyu], ...
                       "E", shape(obj.f_Mass(0,x,V,u), nx, nx), ...
                       "StateName", tag(obj, obj.sv_x), ...
                       "InputName", [reshape(string(sv_V), [], 1); tag(obj, obj.sv_u)], ...
                       "OutputName", tag(obj, sv_y));
end


function sv = tag(obj, sv_name)
    sv_name = reshape(string(sv_name), [], 1);
    if isempty(sv_name)
        sv = strings(0,1);
    else
        sv = reshape(string(obj.attach_tag(sv_name)), [], 1);
    end
end


function M = shape(M, r, c)
    % Models may return [] for an empty or all-zero block
    if isempty(M)
        M = zeros(r,c);
    else
        M = reshape(full(M), r, c);
    end
end
