function [sys, varargout] = get_sys(obj, x, V, I, u, opt)
    arguments
        obj 
        x        (:,1) double = obj.cv_Xequilibrium
        V        (:,1) double = [real(obj.c_Vequilibrium); imag(obj.c_Vequilibrium)]
        I        (:,1) double = [real(obj.c_Iequilibrium); imag(obj.c_Iequilibrium)]
        u        (:,1) double = obj.cv_Uequilibrium                        
        opt.port (1,1) {mustBeMember(opt.port, ["V2I", "I2V"])} = "V2I"
        opt.full (1,1) logical = true
        opt.tag  (1,1) logical = true
        opt.con  (1,1) logical = obj.isController
        opt.rec  (1,1) logical = true
    end        

    [sysCON,x_tag,~,~] = tools.cellfun(@(d) d.get_sys("full",false,"tag",false), obj.a_LocalController);        
    if ~isempty(sysCON) && opt.rec
        [SYS,xSYS,uSYS,ySYS] = obj.get_sys("full",false,"port",opt.port,"tag",false,"con",opt.con,"rec",false);        

        blksys = append(SYS,sysCON{:});                

        blkConnect = connectCondition(blksys.InputGroup,blksys.OutputGroup);
        sysConnect = connectCondition(SYS.InputGroup,SYS.OutputGroup);

        lv_connect = ismember(blkConnect,sysConnect,"rows");
        
        sys = connect(blksys,blkConnect(~lv_connect,:),1:numel(uSYS),1:2);                    

        sys.StateName  = [xSYS; vertcat(x_tag{:})];
        sys.InputName  = uSYS;
        sys.OutputName = ySYS;

        return
    end
    
    xNames = {obj.str_x; obj.attach_tag(obj.str_x)};
    uNames = {obj.str_u; obj.attach_tag(obj.str_u)};    
    yNames = {obj.str_y; obj.attach_tag(obj.str_y)};    

    Vport  = {["Vre";"Vim"]; obj.attach_tag(["Vre";"Vim"])};
    Iport  = {["Ire";"Iim"]; obj.attach_tag(["Ire";"Iim"])};    

    Mass = obj.rm_odeMass([],x,V,I,u);

    Axx = obj.JacobiAxx([],x,V,I,u);
    Bxv = obj.JacobiBxv([],x,V,I,u);    
    Bxu = obj.JacobiBxu([],x,V,I,u);        

    Cix = obj.JacobiCix([],x,V,I,u);
    Div = obj.JacobiDiv([],x,V,I,u);
    Diu = obj.JacobiDiu([],x,V,I,u);                  

    Cyx = {[],obj.JacobiCyx([],x,V,I,u)};
    Dyv = {[],obj.JacobiDyv([],x,V,I,u)};
    Dyu = {[],obj.JacobiDyu([],x,V,I,u)};

    Cvx = {[],zeros(size(Cix),'like',Cix)};
    Dvv = {[],  eye(size(Div),'like',Div)};
    Dvu = {[],zeros(size(Diu),'like',Diu)};

    switch opt.port
        case "V2I"
            A =  Axx;            
            B = [Bxv,Bxu];

            nx = size(A,1);
            nu = size(B,2);

            C  = [eye(opt.full*nx,nx); 
                                  Cix; 
                       Cyx{opt.con+1};
                       Cvx{opt.con+1}];

            D  = [           zeros(opt.full*nx,nu); 
                                        [Div, Diu]; 
                  [Dyv{opt.con+1}, Dyu{opt.con+1}];
                  [Dvv{opt.con+1}, Dvu{opt.con+1}]];            

            InputNames  = [ Vport{opt.tag+1}; 
                           uNames{opt.tag+1};];

            OutputNames = {  Iport{opt.tag+1};
                           [xNames{opt.tag+1}; 
                             Iport{opt.tag+1}]};

        case "I2V"
            inv_Div = Div^-1;

            inv_Axx =  Axx - Bxv * inv_Div * Cix;                       
            inv_Bxv =  Bxv * inv_Div;
            inv_Bxu =  Bxu - Bxv * inv_Div * Diu;
            inv_Cix = -inv_Div * Cix;                        
            inv_Diu = -inv_Div * Diu;                        

            A =  inv_Axx;
            B = [inv_Bxv, inv_Bxu];            

            nx = size(A,1);
            nu = size(B,2);

            C  = [  eye(opt.full*nx,nx); 
                                inv_Cix; 
                         Cyx{opt.con+1}];

            D  = [           zeros(opt.full*nx,nu); 
                                [inv_Div, inv_Diu]; 
                  [Dyv{opt.con+1}, Dyu{opt.con+1}]];            
                        
            InputNames  = [ Iport{opt.tag+1}; 
                           uNames{opt.tag+1}];

            OutputNames = {  Vport{opt.tag+1};
                           [xNames{opt.tag+1}; 
                             Vport{opt.tag+1}]};
    end    

    Vport_ = {[];Vport{opt.tag+1}};

    sys = dss(A, B, C, D, Mass);

    sys.StateName  = xNames{opt.tag+1};
    sys.InputName  = InputNames;
    sys.OutputName = [OutputNames{opt.full+1}; yNames{opt.tag+1}(opt.con); Vport_{isequal(opt.port,"V2I") + opt.con}];        

    rv_ue = numel(sys.InputName);
    rv_oe = numel(sys.OutputName);

    sys.InputGroup  = cell2struct(arrayfun(@(n) {n}, (1:rv_ue)'), sys.InputName);
    sys.OutputGroup = cell2struct(arrayfun(@(n) {n}, (1:rv_oe)'), sys.OutputName);

    varargout{1} = tools.arrayfun(@(s) char(s), xNames{2}); 
    varargout{2} = tools.arrayfun(@(s) char(s), [Vport{2};uNames{2}]); 
    varargout{3} = tools.arrayfun(@(s) char(s), OutputNames{opt.full+1}); 


    function Connect = connectCondition(in,out) 
        Connect = zeros(0,2);

        fi = fieldnames(in);
        fo = fieldnames(out);
    
        idx = 1;
        nv_all = 0;
        while idx<=numel(fo)
            lv = strcmp(fi,fo(idx));
            if any(lv)
                str_i = fi{lv};
                rv_val = in.(str_i);
                nv = numel(rv_val);
    
                Connect(nv_all+(1:nv), :) = [rv_val', repmat(out.(fo{idx}), [nv,1])];
                
                nv_all = nv_all + nv;            
            end
            
            idx = idx + 1;
        end
    end
    
end
