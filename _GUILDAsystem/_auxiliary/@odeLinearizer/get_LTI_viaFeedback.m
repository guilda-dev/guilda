function [A, B, C, D, E] = get_LTI_viaFeedback(obj)  
    net = obj.odeNetwork;
    bus = net.a_Bus;

    % A bus without states whose current does not depend on V in an invertible way (e.g. a load
    % with P = Q = 0) has no I-to-V form, so it is eliminated with the network like a non-unit bus
    l_isU = cellfun(@(b) ~b.l_isNonUnit && has_I2V(b), bus);    

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

    % Global controllers (all of them, one after another, as in Kron and DAE):
    % their inputs are component outputs (e.g. omega) and their outputs add to component inputs (e.g. Pmech)
    for k = 1:numel(net.a_GlobalController)
        sysGC = net.a_GlobalController{k}.get_sys("full",true);
        [lv_out, feedout] = ismember(string(sysGC.InputName),  string(sysODE.OutputName));
        [lv_in,  feedin ] = ismember(string(sysGC.OutputName), string(sysODE.InputName));
        if ~all(lv_out) || ~all(lv_in)
            error("GUILDA:odeLinearizer:GlobalControllerPort", ...
                  "The ports of the global controller '%s' are not found in the linearized system.", net.a_GlobalController{k}.str_tag)
        end
        sysODE = feedback(sysODE, sysGC, feedin, feedout, +1);
    end

    A = sysODE.A;
    B = sysODE.B;
    C = sysODE.C;
    D = sysODE.D;
    E = sysODE.E;

    obj.odeLinearSystem = sysODE;

    function rm_Ymat = complex2matrix(Ymat)
 
        rm_Ymat = cell2mat( arrayfun(@(M) [real(M), -imag(M); imag(M), real(M)], Ymat, 'UniformOutput', false) );                             
        lv_Unit = logical( kron(l_isU,ones(2,1)) );
        rm_Ymat = rm_Ymat(lv_Unit,lv_Unit) - rm_Ymat(lv_Unit,~lv_Unit) * rm_Ymat(~lv_Unit,~lv_Unit)^-1 * rm_Ymat(~lv_Unit,lv_Unit);
    end

end

function tf = has_I2V(bus)
    sys = bus.get_sys("port","V2I","full",false);
    tf  = ~isempty(sys.A) || rcond(sys.D(:,1:2)) > 1e-12;
end
