function sys = get_sys(obj, opt)
    arguments
        obj 
        opt.port (1,1) {mustBeMember(opt.port, ["V2I", "I2V"])} = "V2I"
    end

    sys = tools.cellfun(@(c) c.get_sys(), obj.a_Component);

    Ax = tools.cellfun(@(ss) ss.A                 , sys);
    Bv = tools.cellfun(@(ss) ss.B(:,1:2)          , sys);
    Bu = tools.cellfun(@(ss) ss.B(:,3:end)        , sys);
    Cx = tools.cellfun(@(ss) ss.C(end-1:end, :)   , sys);
    Dv = tools.cellfun(@(ss) ss.D(end-1:end,1:2)  , sys);    
    Du = tools.cellfun(@(ss) ss.D(end-1:end,3:end), sys);    

    StateNames = tools.cellfun(@(ss) ss.StateName , sys);
    InputNames = tools.cellfun(@(c) c.attach_tag(c.str_u), obj.a_Component);    

    Vport = arrayfun(@(str) obj.attach_tag(str), ["Vre";"Vim"]);
    Iport = arrayfun(@(str) obj.attach_tag(str), ["Ire";"Iim"]);
    
    switch opt.port
        case "V2I"
            A =  diag(Ax{:});
            C = [eye(size(A));   diag(Cx{:})];
            B = [vertcat(Bv{:}), diag(Bu{:})];

            nx = size(A,1);
            nu = size(B,2);
            D = [zeros(nx,nu); [sum(Dv{:}), horzcat(Du{:})]];

            InputNames  = [Vport; vertcat(InputNames{:})];
            OutputNames = [vertcat(StateNames{:}); Iport];

        case "I2V"
            Dv = tools.cellfun(@(DV) DV^-1, Dv);
            Cx = tools.cellfun(@(DV,CX) -DV * CX, Dv, Cx);                                      
            Du = tools.cellfun(@(DV,DU) -DV * DU, Dv, Du);
            Bv = tools.cellfun(@(BV,DV) BV*DV, Bv, Dv);
            Ax = tools.cellfun(@(AX,BV,DV,CX) AX - BV*DV*CX, Ax, Bv, Dv, Cx);                       
            Bu = tools.cellfun(@(BV,DV,DU,BU) -BV * DV * DU + BU, Bv, Dv, Du, Bu);

            A =  diag(Ax{:});
            B = [vertcat(Bv{:}), diag(Bu{:})];
            C = [eye(size(A));   diag(Cx{:})];

            nx = size(A,1);
            nu = size(B,2);
            D = [zeros(nx,nu); [sum(Dv{:}), horzcat(Du{:})]];
                        
            InputNames  = [Iport; vertcat(InputNames{:})];
            OutputNames = [vertcat(StateNames{:}); Vport];
    end    


    sys = ss(A,B,C,D);
    sys.StateName  = vertcat(StateNames{:});
    sys.InputName  = InputNames;
    sys.OutputName = OutputNames;

    function mat = sum(varargin)
        nv = cellfun(@(s) size(s,1), varargin);

        mat = zeros(max(nv),2);
        for i=1:nargin            
            mat(end-nv(i)+1:end,:) = mat(end-nv(i)+1:end,:) + varargin{i};
        end
    end

    function mat = horzcat(varargin)        

        nv = cellfun(@(s) size(s,1), varargin);
        nh = cellfun(@(s) size(s,2), varargin);

        mat = zeros(max(nv),nh*ones(nargin,1));
                
        NH = 0;
        for i=1:nargin
            mat( end-nv(i)+1:end, NH+(1:nh(i)) ) = mat( end-nv(i)+1:end, NH+(1:nh(i)) ) + varargin{i};        
            NH = NH + nh(i);
        end
    end

    function mat = diag(varargin)
        nv = cellfun(@(s) size(s,1), varargin);
        nh = cellfun(@(s) size(s,2), varargin);

        if isscalar(varargin)
            mat = varargin{:};
        elseif all(nv-nh == 0) || any(nv == 0)
            mat = blkdiag(varargin{:});
        elseif any(nh == 0)
            varargin(cellfun(@isempty,varargin)) = [];
            mat = blkdiag(varargin{:});        
        end
    end
    
end