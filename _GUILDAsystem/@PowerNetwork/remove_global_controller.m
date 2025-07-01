function remove_global_controller(obj,i_controller)
    arguments
        obj 
        i_controller  (1,1) double {mustBePositive,mustBeInteger}
    end
    obj.GlobalControllers{i_controller}.disband
    obj.GlobalControllers(i_controller) = [];
    obj.onEdit("remove Global Controller"+ i_controller);
end