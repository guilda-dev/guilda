function tab_Ybus2bus = get_admittance_matrix(obj)
% <@Desc>
% Computes the nodal admittance (Y-bus) matrix for the power network.
% <@Role>
% Power Flow
% <@Abst>
% Aggregates admittance contributions from all branches and shunt elements into a bus×bus table.
% <@Signatures>
% [
%   "tab_Ybus2bus = net.get_admittance_matrix()"
% ]
% <@varargout>
% [
%   {
%     "Name": "tab_Ybus2bus",
%     "Type": "table",
%     "Description": "N×N complex admittance matrix table with bus tag names as row and variable names."
%   }
% ]
     
    n_Bus   = numel(str_Bus);
    tab_Ybus2bus   = array2table(zeros(n_Bus,n_Bus),"VariableNames",str_Bus,"RowNames",str_Bus);

    for i = 1:numel(obj.a_Branch)
        br  = obj.a_Branch{i};
        Yij = br.get_admittance_matrix();
        str_iBus = string(br.a_Bus);
        tab_Ybus2bus{str_iBus,str_iBus} = tab_Ybus2bus{str_iBus,str_iBus} + Yij;
    end

    cm_Yshunt = tools.dcellfun(@(b) b.tab_parameter.dynamics{1,["Gshunt","Bshunt"]}*[1;1j], obj.a_Bus);
    tab_Ybus2bus.Variables = cm_Yshunt + tab_Ybus2bus.Variables; 
end