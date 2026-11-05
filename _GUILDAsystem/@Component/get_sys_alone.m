function sys = get_sys_alone(obj, x, V, I, u, opt)
% Linearize the component without its controllers (inner step of get_sys).
%
% Inputs: the port and sv_u. States: sv_x. Outputs: the other port; with
% controllerPorts also sv_y and, for port "V2I", the voltage that the controllers read.
% The names are not tagged, and the groups have the names of the channels so that
% get_sys can connect the controllers by name. The caller checks the edit flags.
%
% See also Component.get_sys, controller.local_LQR
%
% <@Group> Called by analyses
    arguments (Input)
        obj
        x (:,1) double   % States.
        V (:,1) double   % [pu] Bus voltage [Vre; Vim].
        I (:,1) double   % [pu] Current [Ire; Iim].
        u (:,1) double   % Inputs.
        opt.port (1,1) {mustBeMember(opt.port, ["V2I", "I2V"])} = "V2I"   % Input and output ports.
        opt.controllerPorts (1,1) logical = false   % Also output what the controllers read.
    end
    arguments (Output)
        sys   % State-space model with untagged names, grouped by channel.
    end

    nx = numel(obj.sv_x);
    nu = numel(obj.sv_u);
    ny = numel(obj.sv_y);

    Mass = shape(obj.f_Mass(0,x,V,I,u), nx, nx);

    % Same Jacobian contract as SolverODE: f_JacobiDx/I/Y(t,x,V,I,u)
    [Axx,Bxv,Bxi,Bxu] = obj.f_JacobiDx(0,x,V,I,u);
    [Cix,Div,Dii,Diu] = obj.f_JacobiI( 0,x,V,I,u);
    [Cyx,Dyv,Dyi,Dyu] = obj.f_JacobiY( 0,x,V,I,u);

    Axx = shape(Axx, nx, nx);  Bxv = shape(Bxv, nx, 2);  Bxi = shape(Bxi, nx, 2);  Bxu = shape(Bxu, nx, nu);
    Cix = shape(Cix,  2, nx);  Div = shape(Div,  2, 2);  Dii = shape(Dii,  2, 2);  Diu = shape(Diu,  2, nu);
    Cyx = shape(Cyx, ny, nx);  Dyv = shape(Dyv, ny, 2);  Dyi = shape(Dyi, ny, 2);  Dyu = shape(Dyu, ny, nu);

    % The ports are V (input) and I (output), so a model whose equations depend on I cannot be linearized here
    if any([Bxi(:); Dii(:); Dyi(:)] ~= 0)
        error(msg("GUILDA:Component:CurrentDependence", obj.str_tag))
    end

    sv_V = ["Vre";"Vim"];
    sv_I = ["Ire";"Iim"];

    switch opt.port
        case "V2I"
            A = Axx;
            B = [Bxv, Bxu];
            C = Cix;
            D = [Div, Diu];
            sv_in  = [sv_V; obj.sv_u];
            sv_out = sv_I;
            if opt.controllerPorts
                C = [C; Cyx; zeros(2,nx)];
                D = [D; Dyv, Dyu; eye(2), zeros(2,nu)];
                sv_out = [sv_out; obj.sv_y; sv_V];
            end

        case "I2V"
            if ~(rcond(Div) > 1e-12)
                error(msg("GUILDA:Component:NoI2V", obj.str_tag))
            end
            inv_Div = Div^-1;

            inv_Cix = -inv_Div * Cix;
            inv_Diu = -inv_Div * Diu;

            A = Axx - Bxv * inv_Div * Cix;
            B = [Bxv * inv_Div, Bxu - Bxv * inv_Div * Diu];
            C = inv_Cix;
            D = [inv_Div, inv_Diu];
            sv_in  = [sv_I; obj.sv_u];
            sv_out = sv_V;
            if opt.controllerPorts
                % y = Cyx x + Dyv V + Dyu u with V the output: V = inv_Cix x + inv_Div I + inv_Diu u
                C = [C; Cyx + Dyv*inv_Cix];
                D = [D; Dyv*inv_Div, Dyu + Dyv*inv_Diu];
                sv_out = [sv_out; obj.sv_y];
            end
    end

    sys = dss(A, B, C, D, Mass);

    sys.StateName  = obj.sv_x;
    sys.InputName  = sv_in;
    sys.OutputName = sv_out;

    sys.InputGroup  = cell2struct(arrayfun(@(n) {n}, (1:numel(sv_in))'), sys.InputName);
    sys.OutputGroup = cell2struct(arrayfun(@(n) {n}, (1:numel(sv_out))'), sys.OutputName);

end

function M = shape(M,r,c)
    % Models may return [] for an empty or all-zero block
    if isempty(M)
        M = zeros(r,c);
    else
        M = reshape(full(M),r,c);
    end
end
