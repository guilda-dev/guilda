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

    Mass = obj.f_Mass(0,x,V,I,u);

    Axx = obj.JacobiAxx(0,x,V,I,u);
    Bxu = obj.JacobiBxu(0,x,V,I,u);
    Bxv = obj.JacobiBxv(0,x,V,I,u);

    Cyx = obj.JacobiCyx(0,x,V,I,u);
    Dyu = obj.JacobiDyu(0,x,V,I,u);
    Dyv = obj.JacobiDyv(0,x,V,I,u);

    sv_xNames = {obj.sv_x; obj.attach_tag(obj.sv_x)};
    sv_uNames = {obj.sv_u; obj.attach_tag(obj.sv_u)};
    sv_yNames = {obj.sv_y; obj.attach_tag(obj.sv_y)};

    Vport = {["Vre";"Vim"]; obj.attach_tag(["Vre";"Vim"])};

    OutputNames = {sv_yNames{opt.tag+1}; [sv_xNames{opt.tag+1};sv_yNames{opt.tag+1}]};

    A = Axx;
    B = [Bxv, Bxu];

    nx = size(A,1);
    nu = size(B,2);

    C =[eye(opt.full*nx,nx); Cyx];
    D =[zeros(opt.full*nx,nu); [Dyv, Dyu]];

    sys = dss(A, B, C, D, Mass);

    sys.StateName = sv_xNames{opt.tag+1};
    sys.InputName = [Vport{opt.tag+1}; sv_uNames{opt.tag+1}];
    sys.OutputName = OutputNames{opt.full+1};    
    
    rv_ue = numel(sys.InputName);
    rv_oe = numel(sys.OutputName);

    sys.InputGroup  = cell2struct(arrayfun(@(n) {n}, (1:rv_ue)'), sys.InputName);
    sys.OutputGroup = cell2struct(arrayfun(@(n) {n}, (1:rv_oe)'), sys.OutputName);

    varargout{1} = cellfun(@(s) char(s), sv_xNames{end}, 'UniformOutput', false);
    varargout{2} = cellfun(@(s) char(s), sv_uNames{end}, 'UniformOutput', false);
    varargout{3} = cellfun(@(s) char(s), OutputNames{end}, 'UniformOutput', false);

end