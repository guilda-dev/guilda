function [tab_out, struct_out] = information(obj, opt)
    arguments
        obj 
        opt.Display       (1,1) logical = true;
        opt.IncludedClass (1,:) string  = "LayerPackage";
    end

    str_cls    = opt.IncludedClass;
    lv_include = tools.vcellfun(@(cls) isa(obj,cls),str_cls);

    if any(lv_include)
        Index = obj.index;
        Tag   = obj.get_tag(false);
        Class = string(class(obj));
        Parameter = {obj.parameter};
        if ~isnan(obj.parent)
            Belong = obj.parent.get_tag(false);
        else
            Belong = "";
        end
        tab_data = table(Index,Tag,Belong,Class,Parameter);
    else
        tab_data = [];
    end

    tab_out  = [ tab_data; tools.vcellfun( @(child) child.information("Display",false,"IncludedClass",str_cls), obj.children)];

    if nargout==2 || opt.Display
        struct_out = struct;
        [str_unicls, ~, i_unicls] = unique(tab_out.Class);
        for i = 1:numel(str_unicls)
            tab_icls   = tab_out(i_unicls==i,:);
            tab_para   = vertcat(tab_icls.Parameter{:});
            tab_format = [tab_icls(:,1:3),tab_para];
            struct_out.(str_unicls(i)) = tab_format;
            if opt.Display
                disp(newline+" <<"+str_unicls(i),">>"+newline)
                disp(tab_format)
                disp(newline)
            end
        end
    end
end