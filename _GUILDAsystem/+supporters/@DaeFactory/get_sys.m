function sys = get_sys(obj,opt)
arguments
    obj 
    opt.KeepDAEs      (1,1) logical = false;
    opt.KeepDescriptor(1,1) logical = false;

end

    % calculate jacobian
    Asym   = jacobian( obj.eq_diff,   obj.x);
    Bsym   = jacobian( obj.eq_output, obj.u);
    Csym   = jacobian( obj.eq_diff,   obj.x);
    Dsym   = jacobian( obj.eq_iutput, obj.u);

    sv_all = [obj.x;   obj.u;   sym("Time") ];
    rv_all = [obj.xst; obj.ust; 0           ];

    A  = subs( Asym, sv_all, rv_all);
    B  = subs( Bsym, sv_all, rv_all);
    C  = subs( Csym, sv_all, rv_all);
    D  = subs( Dsym, sv_all, rv_all);
    E  = obj.Mass;

    lv_x = diag(Eall)~=0;
    lv_v = diag(Eall)==0;
    
    % DAE to ODE
    if opt.KeepDAEs
        str_x = string(obj.x);
    else
        str_x = string(obj.x(lv_x));

        Axx = A(lv_x,lv_x);
        Axv = A(lv_x,lv_v);
        Avx = A(lv_v,lv_x);
        Avv = A(lv_v,lv_v);
        Bxu = B(alg_x,:);
        Bvu = B(alg_v,:); 
        Cyx = C(:,alg_x);
        Cyv = C(:,alg_u);
        Dyu = D;
    
        if any(abs(eig(Avv))<1e-6)
            warning(config.lang("システム行列内の代数方程式に対応するブロック行列が特異行列となっています。","The block matrix corresponding to the algebraic equations in the system matrix is the singular matrix."))
            iAvv = pinv(Avv);
        else
            iAvv = inv(Avv);
        end
    
        A = Axx - Axv*iAvv*Avx;
        B = Bxu - Axv*iAvv*Bvu;
        C = Cyx - Cyv*iAvv*Avx;
        D = Dyu - Cyv*iAvv*Bvu;
        E = Eall(lv_x,lv_x);
    end

    % Create ss/dss class
    if opt.KeepDescriptor
        sys = dss(A,B,C,D,E);
    else
        A(lv_x,:) = E(lv_x,lv_x)\A(lv_x,:);
        B(lv_x,:) = E(lv_x,lv_x)\B(lv_x,:);
        if opt.KeepDAEs
            E = diag(diag(E)~=0);
            sys = dss(A,B,C,D,E);
        else
            sys = ss(A,B,C,D);
        end
    end
    
    % Name Input/Output/State Name
    str_u = string(obj.u);
    str_y = string(obj.y);

    sys.StateName  = cell(size(str_u));
    [sys.StateName{:} ] = str_x{:};

    sys.InputName  = cell(size(str_u));
    sys.OutputName = cell(size(str_u));

    for i = 1:numel(str_u)
        char_ui = str_u{i};
        sys.InputName{i} = char_ui;
        sys.InputGroup.(char_ui) = i;
    end

    for i = 1:numel(str_y)
        char_yi = str_y{i};
        sys.OutputName{i} = char_yi;
        sys.OutputGroup.(char_yi) = i;
    end

    % In GUILDA, "_B1", "_L1", "_M1", etc. are added as identifiers at the end of variable names of input/output ports.
    % Variable names without "_xxx" are also registered in InputGroup and OutputGroup.
    rmTag = @(name) name(1:(find(name=='_',1,"last")-1));
    [uchar,~,lv_u] = tools.cellfun(@(c) rmTag(c), str_u');
    [ychar,~,lv_y] = tools.cellfun(@(c) rmTag(c), str_u');
    for i =1:numel(uchar)
        sys.InputGroup.(uchar{i}) = find(lv_u==i);
    end
    for i =1:numel(ychar)
        sys.OutputGroup.(ychar{i}) = find(lv_y==i);
    end
end