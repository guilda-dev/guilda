function [A, B, C, D, E] = get_LTI_viaFeedback(obj)  
    net = obj.odeNetwork;
    bus = net.a_Bus;

    l_isU = cellfun(@(b) ~b.l_isNonUnit, bus);    

    ssFromBus = tools.cellfun(@(bs) bs.get_sys("port","I2V","full",true), bus(l_isU));    
    ssG = blkdiag(ssFromBus{:});
    
    busInames = cell2mat( tools.cellfun(@(bi) bi.attach_tag(["Ire";"Iim"]), bus(l_isU)) );
    busVnames = cell2mat( tools.cellfun(@(bi) bi.attach_tag(["Vre";"Vim"]), bus(l_isU)) );

    input  = cellfun(@(s) string(s), ssG.InputName);
    output = cellfun(@(s) string(s), ssG.OutputName);

    lv_input  = ismember(input, busInames);
    lv_output = ismember(output,busVnames);

    Ymat = net.get_admittance_matrix.Variables;
    Ymat = complex2matrix(Ymat);
    ssN  = ss(Ymat);
    ssN.InputName  = vertcat(busVnames{:});
    ssN.OutputName = vertcat(busInames{:});

    sysODE = connect(ssG, ssN, input(~lv_input), output(~lv_output));

    A = sysODE.A;
    B = sysODE.B;
    C = sysODE.C;
    D = sysODE.D;
    E = sysODE.E;

    obj.odeLinearSystem = sysODE;

    function rm_Ymat = complex2matrix(Ymat)
 
        rm_Ymat = cell2mat( arrayfun(@(M) [real(M), -imag(M); imag(M), real(M)], Ymat, 'UniformOutput', false) );                             
        lv_Unit = cellfun(@(b) ~b.l_isNonUnit, bus);    
        lv_Unit = logical( kron(lv_Unit,ones(2,1)) );
        rm_Ymat = rm_Ymat(lv_Unit,lv_Unit) - rm_Ymat(lv_Unit,~lv_Unit) * rm_Ymat(~lv_Unit,~lv_Unit)^-1 * rm_Ymat(~lv_Unit,lv_Unit);
    end

end
