function output_txt = hover_component(obj, i_comp)

    str_tag   = char(obj.str_component(i_comp));
    str_class = replace(char(obj.tab_component.class(i_comp)),'_','\_');
    
    r_I = abs(obj.cv_Icomp(i_comp));
    r_P = obj.rv_Pcomp( i_comp);
    r_Q = obj.rv_Qcomp(i_comp);
    

    output_txt = {['\fontname{SansSerif}\bf{',str_tag,'} @',str_class], ...
                  ['\fontname{Monospaced}{\it |I|} = ', num2str(r_I)]  , ...
                  ['\fontname{Monospaced}{\it P} = ',   num2str(r_P)]  , ...
                  ['\fontname{Monospaced}{\it Q} = ',   num2str(r_Q)]    ...
                  };
end