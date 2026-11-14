function varargout = disp_powerflow(obj)
% Display a stedy-state powerflow of the buses.
%
% <@Examples>
% ```matlab
% net.disp_powerflow()
% ```
%
% <@Group> Queries and display
    arguments (Input)
        obj 
    end
    bar  = string(repmat('=',1,80));
    sep  = @(s) disp( newline+bar+newline+"  "+s+newline+bar+newline);
    sep("Steady-State PowerFlow")
    
    cv_Vst = obj.cv_Vequilibrium;
    cv_Ist = obj.cv_Iequilibrium;
    cv_Sst = cv_Vst .* cv_Ist;

    theta = angle(cv_Vst);
    tab_pf = table(180*theta/pi, theta, abs(cv_Vst), real(cv_Sst), imag(cv_Sst) );
    tab_pf.Properties.VariableNames = ["theta(°)","theta(rad)","|V|(pu)","P(pu)","Q(pu)"];
    tab_pf.Properties.RowNames      = string(obj.a_Bus);
    
    switch nargout
        case 0; disp(tab_pf)
        case 1; varargout{1} = tab_pf;
    end
end