function add_local_controller(obj, a_Controller)
% <@Desc>
% Attaches a LocalController object to this component.
% <@Role>
% Layer Structure
% <@Abst>
% Registers the controller in the component's a_LocalController list.
% <@Signatures>
% [
%   "comp.add_local_controller(a_Controller)"
% ]
% <@varargin>
% [
%   {
%     "Name": "a_Controller",
%     "Type": "Controller",
%     "Description": "LocalController instance to attach to this component.",
%     "Required": true,
%     "Default": "-"
%   }
% ]
    arguments
        obj
        a_Controller (1,1) LocalController
    end
    obj.a_LocalController = [obj.a_LocalController; a_Controller];
end