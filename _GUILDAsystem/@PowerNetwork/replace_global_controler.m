function replace_global_controler(obj,ConInstance,i_controller)
    arguments
        obj 
        ConInstance   (1,1) GlobalController
        i_controller  (1,1) double {mustBePositive,mustBeInteger}
    end
    ConInstance.checkParent;

    con = obj.GlobalControllers{i_controller};
    ConInstance.belong(obj, i_controller)
    ConInstance.connect_component( con.index_observe, con.index_input)
    
    con.disband;
    obj.GlobalControllers{i_controller} = ConInstance;
    obj.onEdit("replace Global Controller"+i_controller);
end
