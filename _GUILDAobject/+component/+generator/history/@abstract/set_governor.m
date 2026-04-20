function set_governor(obj, con)
    arguments
        obj 
        con (1,1) component.generator.governor.base
    end
    con.checkParent;
    con.belong(obj, obj.index );
    obj.SpecificControllers{1} = con;
    obj.onEdit("set governor")
end