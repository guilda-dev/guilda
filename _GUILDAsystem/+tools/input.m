function val = input(disp_msg,input_msg,valtype,candidate)
    flag = true;
    while flag
        fprintf(disp_msg)
        if strcmp(valtype,'str')
            val = input([input_msg,' : '],'s');
        else
            val = input([input_msg,' : ']);
        end
        if ismember(val,candidate)
            flag = false;
        end
    end
end