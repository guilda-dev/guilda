function output_txt = hover_bus(obj, i_bus)

    bustype = char(obj.tab_bus{i_bus,"Type"});
    c_Vbus  = obj.cv_Vbus(i_bus);
    r_Vabs  = abs(c_Vbus);
    r_Varg  = angle(c_Vbus)/pi*180;
    s_tag   = char(obj.sv_bus(i_bus));

    output_txt = {['\bf{',s_tag,' (',bustype,')}'], ...
                  ['\fontname{Monospaced}{\it ∠V} = ' , num2str(r_Varg,"%.2f"),'^\circ'], ...
                  ['\fontname{Monospaced}{\it |V|} = ', num2str(r_Vabs)] ...
                  };
end