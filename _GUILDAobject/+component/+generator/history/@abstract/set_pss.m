function set_pss(obj, con)
    arguments
        obj 
        con (1,1) component.generator.pss.base
    end
    con.checkParent;
    con.belong(obj, obj.index );
    obj.SpecificControllers{3} = con;
    obj.onEdit("set PSS")
end