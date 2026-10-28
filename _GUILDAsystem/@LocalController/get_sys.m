function [sys, varargout] = get_sys(obj, x, V, I, u, opt)
    arguments
        obj
        x        (:,1) double  = obj.rv_Xequilibrium
        V        (:,1) double  = [real(obj.c_Vequilibrium);imag(obj.c_Vequilibrium)]
        I        (:,1) double  = [real(obj.c_Iequilibrium);imag(obj.c_Iequilibrium)]
        u        (:,1) double  = obj.rv_Uequilibrium
        opt.full (1,1) logical = true
        opt.tag  (1,1) logical = true
    end

    % I is not a port of a controller; controllers do not keep it (c_Iequilibrium = [])
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
    sv_yNames = {obj.sv_y; obj.attach_tag(obj.sv_y)};

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
