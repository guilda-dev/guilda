function sct_block = get_linear_matrix(obj, x, V, u)
% Get the linear block of the component alone at a point.
%
% Returns the linear model of the component without its local controllers at the
% states x, the bus voltage V = [Vre; Vim] and the inputs u, as a struct with the fields
% A, B, C, D, E (E dx/dt = A x + B [V; u], [I; y] = C x + D [V; u]) and StateName,
% InputName, OutputName (string columns). The names are the Labels of the variable map
% (comp.get_variable_map): the inputs are the voltage of the bus and the inputs u, the
% states are the states, and the outputs are the current [Ire; Iim] (tagged with the
% component) and the outputs y ("Y_" + name for an output with the name of a state).
%
% get_sys connects these blocks (SolverLIN.solve); a controller that designs with the
% linear model of the component alone (controller.local_LQR) calls it directly. The
% Jacobians are those of the simulation (f_JacobiDx, f_JacobiI, f_JacobiY); a model that
% returns [] for a block gives zeros. The model is not changed.
%
% <@Examples>
% ```matlab
% comp = net.a_Bus{1}.a_Component{1};
% V = [real(comp.c_Vequilibrium); imag(comp.c_Vequilibrium)];
% S = comp.get_linear_matrix(comp.rv_Xequilibrium, V, comp.rv_Uequilibrium);
% eig(S.A, S.E)
% ```
%
% See also PowerSystemModel.get_sys, SolverLIN.solve
%
% <@Group> Called by analyses
    arguments (Input)
        obj
        x (:,1) double   % States of the component.
        V (:,1) double   % [pu] Bus voltage [Vre; Vim].
        u (:,1) double   % Inputs of the component.
    end
    arguments (Output)
        sct_block struct   % Fields A, B, C, D, E, StateName, InputName, OutputName.
    end
    nx = numel(obj.sv_x);
    nu = numel(obj.sv_u);
    ny = numel(obj.sv_y);

    % Same Jacobian contract as SolverODE: f_JacobiDx/I(t,x,V,u), f_JacobiY(t,x,V)
    [Axx,Bxv,Bxu] = obj.f_JacobiDx(0,x,V,u);
    [Cix,Div,Diu] = obj.f_JacobiI( 0,x,V,u);
    [Cyx,Dyv]     = obj.f_JacobiY( 0,x,V);

    Axx = shape(Axx, nx, nx);  Bxv = shape(Bxv, nx, 2);  Bxu = shape(Bxu, nx, nu);
    Cix = shape(Cix,  2, nx);  Div = shape(Div,  2, 2);  Diu = shape(Diu,  2, nu);
    Cyx = shape(Cyx, ny, nx);  Dyv = shape(Dyv, ny, 2);

    sv_y = reshape(string(obj.sv_y), [], 1);
    lv_yx = ismember(sv_y, obj.sv_x);
    sv_y(lv_yx) = "Y_" + sv_y(lv_yx);
    sv_V = ["Vre";"Vim"];
    if ~isempty(obj.a_Bus)
        sv_V = obj.a_Bus.attach_tag(sv_V);
    end
    sct_block = struct("A", Axx, "B", [Bxv, Bxu], "C", [Cix; Cyx], "D", [Div, Diu; Dyv, zeros(ny,nu)], ...
                       "E", shape(obj.f_Mass(0,x,V,u), nx, nx), ...
                       "StateName", tag(obj, obj.sv_x), ...
                       "InputName", [reshape(string(sv_V), [], 1); tag(obj, obj.sv_u)], ...
                       "OutputName", [tag(obj, ["Ire";"Iim"]); tag(obj, sv_y)]);
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
