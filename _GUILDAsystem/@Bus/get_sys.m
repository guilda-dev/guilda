function sys = get_sys(obj, opt)
    arguments
        obj 
        opt.port (1,1) {mustBeMember(opt.port, ["V2I", "I2V"])}
    end

    sys = tools.cellfun(@(c) c.get_sys(), obj.a_Component);

    Ax = tools.cellfun(@(ss) ss.A         , sys);
    Bv = tools.cellfun(@(ss) ss.B(:,1:2)  , sys);
    Bu = tools.cellfun(@(ss) ss.B(:,3:end), sys);
    Cx = tools.cellfun(@(ss) ss.C         , sys);
    Dv = tools.cellfun(@(ss) ss.D(:,1:2)  , sys);    
    Du = tools.cellfun(@(ss) ss.D(:,3:end), sys);    

    StateNames  = cell2mat( tools.cellfun(@(ss) ss.StateName , sys) );
    InputNames  = cell2mat( tools.cellfun(@(ss) ss.InputName , sys) );
    OutputNames = cell2mat( tools.cellfun(@(ss) ss.OutputName, sys) );
    
    switch opt.port
        case "V2I"
            A = blkdiag(Ax{:});
            C = blkdiag(Cx{:});
            B = [vertcat(Bv{:})     , blkdiag(Bu{:})];
            D = [sum(cat(3,Dv{:}),3), horzcat(Du{:})];

        case "I2V"
            Dv = tools.cellfun(@(DV) DV^-1, Dv);
            Cx = tools.cellfun(@(DV,CX) -DV * CX, Dv,Cx);                                      
            Du = tools.cellfun(@(DV,DU) -DV * DU, Dv,Du);
            Bv = tools.cellfun(@(BV,DV) BV*DV, Bv,Dv);
            Ax = tools.cellfun(@(AX,BV,DV,CX) AX - BV*DV*CX, Ax,Bv,Dv,Cx);                       
            Bu = tools.cellfun(@(BV,DV,DU,BU) -BV * DV * DU + BU, Bv,Dv,Du,Bu);

            A =  blkdiag(Ax{:});
            B = [vertcat(Bv{:})     , blkdiag(Bu{:})];
            C =  blkdiag(Cx{:});
            D = [sum(cat(3,Dv{:}),3), horzcat(Du{:})];
            
            [InputNames, OutputNames] = deal(OutputNames, InputNames);
    end    


    sys = ss(A,B,C,D);
    sys.StateName  = StateNames;
    sys.InputName  = InputNames;
    sys.OutputName = OutputNames;
    
end