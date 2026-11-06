function G = draw_spring_model(obj,mode)
% Draw the network as an interactive mass-spring graph.
%
% Nodes are buses and edges are branches; hovering shows the branch admittance and
% the bus data for the chosen mode.
%
% See also PowerNetwork.draw_diagram, GraphMassSpring
%
% <@Group> Queries and display
    arguments (Input)
        obj 
        mode (1,1) string {mustBeMember(mode,["CalculatePowerFlow","DynamicSimulation"])}   % Bus data to show: "CalculatePowerFlow" or "DynamicSimulation".
    end
    arguments (Output)
        G   % GraphMassSpring object of the drawing.
    end

    a_Bus = obj.a_Bus;
    a_Bra = obj.a_Branch;

    n_Bus = numel(a_Bus);
    n_Bra = numel(a_Bra);

    sv_Bus  = string(a_Bus);
    sv_Bra  = string(a_Bra);

    sm_edge = tools.hcellfun(@(bra) string(bra.a_Bus(:)), a_Bra)' ;
    [~,im_edge]  = ismember(sm_edge, sv_Bus);

    rm_BusCol = repmat([0.2, 0.7, 0.2, 1.0], n_Bus, 1);
    rv_Radii  = ones(1,n_Bus)*0.08;

    for i = 1:n_Bra
        tab_Bra = a_Bra{i}.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", a_Bra{i}.a_Parameter)}.tab_parameter;
        RX = tab_Bra.Rij + 1j*tab_Bra.Xij;
        GB = 1/RX;
        s_fromto   =  "("+sm_edge(i,1)+"--"+sm_edge(i,2)+")"+newline;
        s_GBij     = sprintf("Conductance(G):%.4f\nSusceptance(B):%.4f", real(GB), imag(GB));
        sv_Bra(i) = sv_Bra(i) + s_fromto + s_GBij;
    end

    switch mode
        case "CalculatePowerFlow"
            for i=1:n_Bus
                [tag,col,rad] = get_BusDat_PF(a_Bus{i});
                sv_Bus(i)     = sv_Bus(i)+tag;
                rm_BusCol(i,:) = col;
                rv_Radii(i)    = rad;
            end
            G = GraphMassSpring(n_Bus,im_edge, ...
                "nodeRadii", rv_Radii, ...
                "nodeColors",rm_BusCol, ...
                "hoverNodeTexts",sv_Bus, ...
                "hoverEdgeTexts",sv_Bra);
        case "DynamicSimulation"
            s_Mac   = [];
            s_Out   = [];
    end
end


function [tag,col,rad] = get_BusDat_PF(bus)
    tab_bus  = bus.get_pf_set;
    sv_type  = tab_bus.Type;
    switch sv_type
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
    tag = "("+sv_type+")"+ newline + "PowerFlowSet >> "+tag;
    rad = 0.08;
end

function [tag,col,rad] = get_BusDat_Sim(bus)
    tab_bus  = bus.get_pf_set;
    sv_type  = tab_bus.Type;

    c_Vst = bus.c_Vequilibrium;
    c_Ist = bus.c_Iequilibrium;
    c_Sst = c_Vst * conj(c_Ist);
    c_Pst = real(c_Sst);
    c_Qst = real(c_Sst);

    tag = "("+sv_type+")"+ newline + "OperatingPoint >> " + ...
          sprintf("Vang:%.2f°, V:%.2f, P:%.2f, Q:%.2f",angle(c_Vst),abs(c_Vst),c_Pst,c_Qst);
    col = [0,0,0,1];
    rad = 0.01;
end