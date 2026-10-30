function [sys, varargout] = get_sys(obj, x, V, I, u, opt)
% <@Desc>
% Linear model of the controller alone: inputs are the bus voltage [Vre; Vim] and the
% inputs sv_u, states are sv_x and outputs are sv_y (an output with the name of a state
% is labelled "Y_" + name). The point is x, V, u (default: the equilibrium). Its
% connection to the component is in comp.get_sys. The model is not changed.
% <@Role> Static Analysis
% <@Summary> Linear model of the controller (u to y).
% <@Signatures>
% [
%   "sys = con.get_sys()",
%   "sys = con.get_sys(x, V, I, u)"
% ]
% <@Parameters>
% [
%   {"Name": "x, V, I, u", "Type": "double column", "Description": "States, bus voltage [Vre; Vim], current (unused) and inputs of the controller.", "Required": false, "Default": "the equilibrium"}
% ]
% <@Returns>
% [
%   {"Name": "sys", "Type": "ss", "Description": "Descriptor state-space model with state, input and output names."}
% ]
    arguments
        obj
        x        (:,1) double  = obj.rv_Xequilibrium
        V        (:,1) double  = [real(obj.c_Vequilibrium);imag(obj.c_Vequilibrium)]
        I        (:,1) double  = [real(obj.c_Iequilibrium);imag(obj.c_Iequilibrium)]
        u        (:,1) double  = obj.rv_Uequilibrium
        opt.full (1,1) logical = false     % also output the states
        opt.tag  (1,1) logical = true
    end

    % I is not a port of a controller (c_Iequilibrium is the parent's, [] without a parent)
    if isempty(I)
        I = zeros(2,1);
    end

    nx = numel(obj.sv_x);
    nu = numel(obj.sv_u);
    ny = numel(obj.sv_y);

    Mass = shape(obj.f_Mass(0,x,V,I,u), nx, nx);

    % Same Jacobian contract as odeSimulator: f_JacobiDx/Y(t,x,V,I,u)
    [Axx,Bxv,~,Bxu] = obj.f_JacobiDx(0,x,V,I,u);
    [Cyx,Dyv,~,Dyu] = obj.f_JacobiY( 0,x,V,I,u);

    Axx = shape(Axx, nx, nx);  Bxv = shape(Bxv, nx, 2);  Bxu = shape(Bxu, nx, nu);
    Cyx = shape(Cyx, ny, nx);  Dyv = shape(Dyv, ny, 2);  Dyu = shape(Dyu, ny, nu);

    sv_xNames = {obj.sv_x; obj.attach_tag(obj.sv_x)};
    sv_uNames = {obj.sv_u; obj.attach_tag(obj.sv_u)};
    sv_yLabel = obj.sv_y;
    lv_yx     = ismember(sv_yLabel, obj.sv_x);
    sv_yLabel(lv_yx) = "Y_" + sv_yLabel(lv_yx);       % unique names (for tagged labels)
    sv_yNames = {obj.sv_y; obj.attach_tag(sv_yLabel)};

    Vport = {["Vre";"Vim"]; obj.attach_tag(["Vre";"Vim"])};

    OutputNames = {sv_yNames{opt.tag+1}; [sv_xNames{opt.tag+1};sv_yNames{opt.tag+1}]};

    A = Axx;
    B = [Bxv, Bxu];

    C =[eye(opt.full*nx,nx); Cyx];
    D =[zeros(opt.full*nx,nu+2); [Dyv, Dyu]];

    sys = dss(A, B, C, D, Mass);

    sys.StateName = sv_xNames{opt.tag+1};
    sys.InputName = [Vport{opt.tag+1}; sv_uNames{opt.tag+1}];
    sys.OutputName = OutputNames{opt.full+1};

    rv_ue = numel(sys.InputName);
    rv_oe = numel(sys.OutputName);

    sys.InputGroup  = cell2struct(arrayfun(@(n) {n}, (1:rv_ue)'), sys.InputName);
    sys.OutputGroup = cell2struct(arrayfun(@(n) {n}, (1:rv_oe)'), sys.OutputName);

    varargout{1} = cellfun(@(s) char(s), cellstr(sv_xNames{end}), 'UniformOutput', false);
    varargout{2} = cellfun(@(s) char(s), cellstr(sv_uNames{end}), 'UniformOutput', false);
    varargout{3} = cellfun(@(s) char(s), cellstr(OutputNames{end}), 'UniformOutput', false);

end

function M = shape(M,r,c)
    % Models may return [] for an empty or all-zero block
    if isempty(M)
        M = zeros(r,c);
    else
        M = reshape(full(M),r,c);
    end
end
