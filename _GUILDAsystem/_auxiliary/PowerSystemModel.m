classdef PowerSystemModel < LayerPackage
% <@Desc>
% The PowerSystemModel class serves as a base class for classes that constitute the power system model.
% It is designed to separate classes that make up the power system model from those intended for analysis assistance.
% - Classes that constitute the power system model >> Inherit from PowerSystemModel
% - Classes intended for analysis assistance >> Inherit from auxiliary
% <@Role> Class Category
% <@Constructor> None

    properties (Dependent, SetAccess=private)
        % <@Desc> Nominal frequency [Hz] of the network the model belongs to
        % (net.tab_parameter.base.Hz; GUILDA.config("Model","Hz") when not attached to a network).
        % This is the omega0 passed to the model functions (models multiply it by 2*pi).
        % <@Role> Parameter
        % <@Type> double
        % <@Size> 1x1
        r_Hz
    end
    methods
        function Hz = get.r_Hz(obj)
            Hz = obj.get_Hz();
        end
    end
end
