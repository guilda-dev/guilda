function out = attach_tag(obj,str_name_list)
    arguments
        obj 
        str_name_list (1,:) string
    end
    out = str_name_list +"_"+ obj.getTag(true);
end