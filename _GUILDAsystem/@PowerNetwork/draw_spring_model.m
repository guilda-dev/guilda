function G = draw_spring_model(obj,mode)
    arguments
        obj 
        mode (1,1) string {mustBeMember(mode,["CalculatePowerFlow","DynamicSimulation"])}
    end

    a_Bus = obj.a_Bus;
    a_Bra = obj.a_Branch;

    n_Bus = numel(a_Bus);
    n_Bra = numel(a_Bra);

    str_Bus = string(a_Bus);
    str_Bra = string(a_Bra);

    str_edge = tools.hcellfun(@(bra) string(bra.a_Bus(:)), a_Bra)' ;
    [~,im_edge]  = ismember(str_edge, str_Bus);

    rm_BusCol = repmat([0.2, 0.7, 0.2, 1.0], n_Bus, 1);
    rv_Radii  = ones(1,n_Bus)*0.08;

    for i = 1:n_Bra
        tab_Bra = a_Bra{i}.para_dynamics;
        RX = tab_Bra.Rij + 1j*tab_Bra.Xij;
        GB = 1/RX;
        str_fromto =  "("+str_edge(i,1)+"--"+str_edge(i,2)+")"+newline;
        str_GBij   = sprintf("Conductance(G):%.4f\nSusceptance(B):%.4f", real(GB), imag(GB));
        str_Bra(i) = str_Bra(i) + str_fromto + str_GBij;
    end

    switch mode
        case "CalculatePowerFlow"
            for i=1:n_Bus
                [tag,col,rad] = get_BusDat_PF(a_Bus{i});
                str_Bus(i)     = str_Bus(i)+tag;
                rm_BusCol(i,:) = col;
                rv_Radii(i)    = rad;
            end
            G = GraphMassSpring(n_Bus,im_edge, ...
                "nodeRadii", rv_Radii, ...
                "nodeColors",rm_BusCol, ...
                "hoverNodeTexts",str_Bus, ...
                "hoverEdgeTexts",str_Bra);
        case "DynamicSimulation"
            str_Mac = [];
            str_Out = [];
    end
end


function [tag,col,rad] = get_BusDat_PF(bus)
    tab_bus  = bus.get_pf_set;
    str_type = tab_bus.Type;
    switch str_type
        case "slack"
            tag = "Varg:"+tab_bus.Varg+", V:"+tab_bus.V;
            col = [1,0,0,1];
        case "PV"
            tag = "P:"+tab_bus.P+", V:"+tab_bus.V;
            col = [0,1,0,1];
        case "PQ"
            tag = "P:"+tab_bus.P+", Q:"+tab_bus.Q;
            col = [0,0,1,1];
        otherwise
            tag = "";
            col = [0,0,0,1];
    end
    tag = "("+str_type+")"+ newline + "PowerFlowSet >> "+tag;
    rad = 0.08;
end

function [tag,col,rad] = get_BusDat_Sim(bus)
    tab_bus  = bus.get_pf_set;
    str_type = tab_bus.Type;

    c_Vst = bus.c_Vequilibrium;
    c_Ist = bus.c_Iequilibrium;
    c_Sst = c_Vst * conj(c_Ist);
    c_Pst = real(c_Sst);
    c_Qst = real(c_Sst);

    tag = "("+str_type+")"+ newline + "OperatingPoint >> " + ...
          sprintf("Vang:%.2f°, V:%.2f, P:%.2f, Q:%.2f",angle(c_Vst),abs(c_Vst),c_Pst,c_Qst);
    col = [0,0,0,1];
    rad = 0.01;
end