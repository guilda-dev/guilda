function sys = get_sys(obj, opt)
    arguments
        obj 
        opt.port (1,1) {mustBeMember(opt.port, ["V2I", "I2V"])}
    end

        sslin = cellfun(@(c) c.odeLinearSystem, obj.a_Component);        

        lv_Bv = tools.cellfun(@(c) ismember(fieldnames(c.odeLinearSystem.InputGroup), obj.attach_tag( ["Vre","Vim"] )), obj.a_Component);       

        Cv = cellfun()


        Cv{idx} = sslin.D(:, lg_Bv)^-1;
        Cx{idx} = -Cv{idx} * sslin.C;                                      
        Du{idx} = -Cv{idx} * sslin.D(:,~lg_Bv);
        Av{idx} = sslin.B(:, lg_Bv)*Cv{idx};
        Ax{idx} = sslin.A - Av{idx}*Cv{idx}*Cx{idx};                       
        Bu{idx} = -Av{idx} * Cv{idx} * Du{idx} + sslin.B(:,~lg_Bv);                                                                                                                   
       
       
        if idx == 1
            arrayfun(@(S) attach_itag(S,"ode"), ["Ire","Iim"]+"_"+bus{i}.str_tag);                               
            arrayfun(@(S) attach_itag(S,"net"), ["Ire","Iim"]+"_"+bus{i}.str_tag);    
            arrayfun(@(S) attach_otag(S,"ode"), ["Vre","Vim"]+"_"+bus{i}.str_tag);                       
            arrayfun(@(S) attach_otag(S,"net"), ["Vre","Vim"]+"_"+bus{i}.str_tag);                       
        end

        u_idx = reshape(comp{idx}.str_u+"_"+comp{idx}.str_tag, 1, []); 
        arrayfun(@(S,N) attach_itag(S,"ode"), u_idx);                       
    
end