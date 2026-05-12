function sys = get_sys(obj, opt)
    arguments
        obj 
        opt.port (1,1) {mustBeMember(opt.port, ["V2I", "I2V"])} = "V2I"
        opt.full (1,1) logical = false
    end

    sys = tools.cellfun(@(c) c.get_sys("port", "V2I", "full", opt.full), obj.a_Component);

    Ax = tools.cellfun(@(ss) ss.A                 , sys);
    Bv = tools.cellfun(@(ss) ss.B(:,1:2)          , sys);
    Bu = tools.cellfun(@(ss) ss.B(:,3:end)        , sys);
    Cx = tools.cellfun(@(ss) ss.C(end-1:end,:)    , sys);
    Dv = tools.cellfun(@(ss) ss.D(end-1:end,1:2)  , sys);    
    Du = tools.cellfun(@(ss) ss.D(end-1:end,3:end), sys);    

    E = tools.cellfun(@(ss) ss.E, sys);

    StateNames = tools.cellfun(@(ss) ss.StateName , sys);
    InputNames = tools.cellfun(@(c) c.attach_tag(c.str_u), obj.a_Component);    

    Vport = arrayfun(@(str) obj.attach_tag(str), ["Vre";"Vim"]);
    Iport = arrayfun(@(str) obj.attach_tag(str), ["Ire";"Iim"]);
    
    switch opt.port
        case "V2I"
            A =  blkdiag(Ax{:});            
            B = [vertcat(Bv{:}), blkdiag(Bu{:})];

            nx = size(A,1);
            nu = size(B,2);            

            C  = [  eye(opt.full*nx,nx); horzcat(Cx{:})];
            D  = [zeros(opt.full*nx,nu); [sum( cat(3,Dv{:}),3 ), horzcat(Du{:})]];            

            InputNames  = [Vport; vertcat(InputNames{:})];
            OutputNames = {Iport;[vertcat(StateNames{:}); Iport]};

        case "I2V"
            inv_Dv = sum( cat(3,Dv{:}),3 )^-1;
            inv_Cx = horzcat(Cx{:});
            inv_Du = horzcat(Du{:});       
            inv_Ax = blkdiag(Ax{:}) - vertcat(Bv{:}) * inv_Dv * inv_Cx;                       
            inv_Bv = vertcat(Bv{:})*inv_Dv;            
            inv_Bu = blkdiag(Bu{:}) - vertcat(Bv{:}) * inv_Dv * inv_Du;

            A =  inv_Ax;
            B = [inv_Bv, inv_Bu];            

            nx = size(A,1);
            nu = size(B,2);            
                        
            C  = [  eye(opt.full*nx,nx); -inv_Dv*inv_Cx];
            D  = [zeros(opt.full*nx,nu); [inv_Dv, -inv_Dv*inv_Du]];            
            InputNames  = [Iport; vertcat(InputNames{:})];
            OutputNames = {Vport;[vertcat(StateNames{:}); Vport]};
    end    


    sys = dss(A,B,C,D,blkdiag(E{:}));
    sys.StateName  = vertcat(StateNames{:});
    sys.InputName  = InputNames;
    sys.OutputName = OutputNames{opt.full+1};
    
end