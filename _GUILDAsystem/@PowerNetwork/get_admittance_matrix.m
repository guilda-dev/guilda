function tab_Ybus2bus = get_admittance_matrix(obj)
% Return the bus admittance matrix of the network as a table.
%
% Rows and columns are the bus tags in the order of `a_Bus`. The matrix sums the
% admittance matrices of the branches and the shunt admittances Gshunt + j*Bshunt of
% the buses, in per unit.
%
% <@Examples>
% ```matlab
% tab_Y = net.get_admittance_matrix();
% Y = tab_Y.Variables;
% ```
%
% See also Branch.get_admittance_matrix
%
% <@Group> Called by analyses
    arguments (Input)
        obj
    end
    arguments (Output)
        tab_Ybus2bus   % [pu] Admittance matrix (complex) with bus tags as row and variable names.
    end

    sv_Bus = string(obj.a_Bus);
     
    n_Bus   = numel(sv_Bus);
    tab_Ybus2bus   = array2table(zeros(n_Bus,n_Bus),"VariableNames",sv_Bus,"RowNames",sv_Bus);

    for i = 1:numel(obj.a_Branch)
        br  = obj.a_Branch{i};
        Yij = br.get_admittance_matrix();
        sv_iBus = string(br.a_Bus);
        tab_Ybus2bus{sv_iBus,sv_iBus} = tab_Ybus2bus{sv_iBus,sv_iBus} + Yij;
    end

    cm_Yshunt = tools.dcellfun(@(b) [b.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", b.a_Parameter)}.Gshunt, b.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", b.a_Parameter)}.Bshunt]*[1;1j], obj.a_Bus);
    tab_Ybus2bus.Variables = cm_Yshunt + tab_Ybus2bus.Variables; 
end