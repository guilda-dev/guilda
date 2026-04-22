function [A, B, C, D] = get_LTI_viaFeedback(obj)  
    net = obj.odeNetwork;
    bus = net.a_Bus;

    l_isU = cellfun(@(b) ~b.l_isNonUnit, bus);    

    ssFromBus = tools.cellfun(@(bs) bs.get_sys("port","I2V"), bus(l_isU));    
    ssG = blkdiag(ssFromBus{:});

    [input, output] = get_IO_port();    
    busInames = tools.cellfun(@(bi) bi.attach_tag(["Ire";"Iim"]), bus(l_isU));
    busVnames = tools.cellfun(@(bi) bi.attach_tag(["Vre";"Vim"]), bus(l_isU));

    Ymat = complex2matrix(net.get_admittance_matrix.Variables);
    ssN  = ss(Ymat);
    ssN.InputName  = vertcat(busVnames{:});
    ssN.OutputName = vertcat(busInames{:});

    sysODE = connect(ssG, ssN, input, output);

    A = sysODE.A;
    B = sysODE.B;
    C = sysODE.C;
    D = sysODE.D;

    obj.odeLinearSystem = sysODE;

    function rm_Ymat = complex2matrix(Ymat)
 
        rm_Ymat = cell2mat( arrayfun(@(M) [real(M), -imag(M); imag(M), real(M)], Ymat, 'UniformOutput', false) );                             
        lv_Unit = cellfun(@(b) ~b.l_isNonUnit, bus);    
        lv_Unit = logical( kron(lv_Unit,ones(2,1)) );
        rm_Ymat = rm_Ymat(lv_Unit,lv_Unit) - rm_Ymat(lv_Unit,~lv_Unit) * rm_Ymat(~lv_Unit,~lv_Unit)^-1 * rm_Ymat(~lv_Unit,lv_Unit);
    end


    function [input, output] = get_IO_port()
        BUS = obj.odeNetwork.a_Bus;

        input  = cell(numel(BUS),1);
        output = cell(numel(BUS),1);
        for argi = 1:numel(BUS)
            COMP = BUS{argi}.a_Component;

            str_x = [];
            str_u = [];                   
            if argi ~= obj.odeNonUnitBus                
                str_x = cell2mat( cellfun(@(C) C.attach_tag(C.str_x), COMP, 'UniformOutput', false) );
                str_u = cell2mat( cellfun(@(C) C.attach_tag(C.str_u), COMP, 'UniformOutput', false) );                                          
            end

            input{argi}  = str_u;
            output{argi} = str_x;
        end

        input  = cell2mat(input);
        output = cell2mat(output);
   end

end
