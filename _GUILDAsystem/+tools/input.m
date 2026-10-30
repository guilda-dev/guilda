function val = input(disp_msg,input_msg,valtype,candidate)
% Ask for a value at the Command Window until it is one of the candidates.
%
% Inputs: `disp_msg` (text printed before each prompt), `input_msg` (prompt), `valtype`
% ("str" to read text, anything else to evaluate the input) and `candidate` (accepted
% values). Output `val`: the accepted value.
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