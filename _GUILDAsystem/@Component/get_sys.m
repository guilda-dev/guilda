function [sys, varargout] = get_sys(obj, x, V, I, u, opt)
% Linearize the component with its local controllers (V to I, or I to V).
%
% Linear model of the component with its local controllers, from the bus voltage V and
% the inputs u to the current I (port "V2I") or from I to V (port "I2V").
% The point of the linearization is x, V, I, u (default: the equilibrium; the local
% controllers are then linearized at their equilibrium), or Point in the same form as
% net.linearize: a vector in the order of comp.get_variable_map() (states of the
% component and its controllers, Vre, Vim, inputs), or {sim, t}. With Point, I is
% fcn_I at the point and the inputs of the controllers are the outputs they are
% connected to (as in the simulation). The model is not changed.
%
% Outputs: `sys`, a descriptor state-space model with state, input and output names;
% then (`varargout`) the state, input and output names as cell arrays of char.
%
% See also Component.get_variable_map, Bus.get_sys, PowerNetwork.get_sys
    arguments
        obj 
        x        (:,1) double = obj.rv_Xequilibrium   % States (default: the equilibrium).
        V        (:,1) double = [real(obj.c_Vequilibrium); imag(obj.c_Vequilibrium)]   % [pu] Bus voltage [Vre; Vim] (default: the equilibrium).
        I        (:,1) double = [real(obj.c_Iequilibrium); imag(obj.c_Iequilibrium)]   % [pu] Current [Ire; Iim] (default: the equilibrium).
        u        (:,1) double = obj.rv_Uequilibrium   % Inputs (default: the equilibrium).
        opt.port (1,1) {mustBeMember(opt.port, ["V2I", "I2V"])} = "V2I"   % Input and output ports.
        opt.full (1,1) logical = true   % Also output the states.
        opt.tag  (1,1) logical = true   % Name the states, inputs and outputs with the component tag.
        opt.con  (1,1) logical = obj.l_hasController   % Include the local controllers (default: true when one is attached).
        opt.rec  (1,1) logical = true   % Internal: false for the inner call that linearizes the component alone.
        opt.Point = []   % Point of the linearization; overrides x, V, I, u.
    end        

    % All controllers in the tree (e.g. PSS attached under AVR) are separate blocks connected by signal names
    a_LC = all_controllers(obj);
    if isempty(opt.Point) && ~iscell(opt.Point)
        [sysCON,x_tag,~,~] = tools.cellfun(@(d) d.get_sys("full",false,"tag",false), a_LC);
    else
        [x, V, I, u, c_con] = point_values(obj, a_LC, odeLinearizer.point_vector(obj, opt.Point));
        [sysCON,x_tag,~,~] = tools.cellfun(@(d,p) d.get_sys(p{:},"full",false,"tag",false), a_LC, c_con);
    end
    if ~isempty(sysCON) && opt.rec
        [SYS,xSYS,uSYS,ySYS] = obj.get_sys(x,V,I,u,"full",false,"port",opt.port,"tag",false,"con",opt.con,"rec",false);        

        blksys = append(SYS,sysCON{:});            

        blkConnect = connectCondition(blksys.InputGroup,blksys.OutputGroup);
        sysConnect = connectCondition(SYS.InputGroup,SYS.OutputGroup);

        lv_connect = ismember(blkConnect,sysConnect,"rows");                        

        opt = connectOptions("Simplify",false);
        
        sys = connect(blksys,blkConnect(~lv_connect,:),1:numel(uSYS),1:2,opt);                                    

        sys.StateName  = [xSYS; vertcat(x_tag{:})];
        sys.InputName  = uSYS;
        sys.OutputName = ySYS;

        return
    end
    
    xNames = {obj.sv_x; obj.attach_tag(obj.sv_x)};
    uNames = {obj.sv_u; obj.attach_tag(obj.sv_u)};    
    yNames = {obj.sv_y; obj.attach_tag(obj.sv_y)};    

    Vport  = {["Vre";"Vim"]; obj.attach_tag(["Vre";"Vim"])};
    Iport  = {["Ire";"Iim"]; obj.attach_tag(["Ire";"Iim"])};    

    nx = numel(obj.sv_x);
    nu = numel(obj.sv_u);
    ny = numel(obj.sv_y);

    Mass = shape(obj.f_Mass(0,x,V,I,u), nx, nx);

    % Same Jacobian contract as odeSimulator: f_JacobiDx/I/Y(t,x,V,I,u)
    [Axx,Bxv,Bxi,Bxu] = obj.f_JacobiDx(0,x,V,I,u);
    [Cix,Div,Dii,Diu] = obj.f_JacobiI( 0,x,V,I,u);
    [Cyx,Dyv,Dyi,Dyu] = obj.f_JacobiY( 0,x,V,I,u);

    Axx = shape(Axx, nx, nx);  Bxv = shape(Bxv, nx, 2);  Bxi = shape(Bxi, nx, 2);  Bxu = shape(Bxu, nx, nu);
    Cix = shape(Cix,  2, nx);  Div = shape(Div,  2, 2);  Dii = shape(Dii,  2, 2);  Diu = shape(Diu,  2, nu);
    Cyx = shape(Cyx, ny, nx);  Dyv = shape(Dyv, ny, 2);  Dyi = shape(Dyi, ny, 2);  Dyu = shape(Dyu, ny, nu);

    % The ports are V (input) and I (output), so a model whose equations depend on I cannot be linearized here
    if any([Bxi(:); Dii(:); Dyi(:)] ~= 0)
        error("GUILDA:Component:get_sys:CurrentDependence", ...
              "get_sys does not support models whose fcn_dx, fcn_I or fcn_Y depend on the current I (%s).", obj.str_tag)
    end

    Cyx = {[],Cyx};
    Dyv = {[],Dyv};
    Dyu = {[],Dyu};

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


    function list = all_controllers(parent)
        list = cell(0,1);
        for k = 1:numel(parent.a_LocalController)
            con  = parent.a_LocalController{k};
            list = [list; {con}; all_controllers(con)]; %#ok<AGROW>
        end
    end

    function M = shape(M,r,c)
        % Models may return [] for an empty or all-zero block
        if isempty(M)
            M = zeros(r,c);
        else
            M = reshape(full(M),r,c);
        end
    end

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
