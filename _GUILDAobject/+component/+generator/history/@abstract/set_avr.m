function set_avr(obj, con)
    arguments
        obj 
        con (1,1) component.generator.avr.base
    end
    con.checkParent;
    con.belong(obj, obj.index );
    obj.SpecificControllers{2} = con;
    obj.onEdit("set AVR")
end