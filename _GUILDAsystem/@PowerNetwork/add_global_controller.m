function add_global_controller(obj, ConInstance, index_observe, index_input)
    arguments
        obj 
        ConInstance   (1,1) GlobalController
        index_observe (1,:) {mustBeA(index_observe,["double","cell"])} = controller.index_observe;
        index_input   (1,:) {mustBeA(index_input,  ["double","cell"])} = controller.index_input;
    end
    ConInstance.checkParent;
    ConInstance.belong(obj, numel(obj.GlobalControllers)+1 );
    ConInstance.connect_component(index_observe, index_input);
    obj.GlobalControllers = [obj.GlobalControllers; {ConInstance}];
    obj.onEdit('add Global Controller')
end