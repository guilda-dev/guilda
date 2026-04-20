function add_local_controller(obj, a_Controller)
    arguments
        obj
        a_Controller (1,1) Controller
    end
    obj.a_LocalController = [obj.a_LocalController; a_Controller];
end