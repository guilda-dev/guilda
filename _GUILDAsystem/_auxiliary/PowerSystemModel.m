classdef PowerSystemModel < LayerPackage
% Base class of the classes that constitute the power system model.
%
% PowerNetwork, Bus, Branch, Component, LocalController and GlobalController derive from
% it. It separates the classes that make up the power system model from those intended
% for analysis assistance:
%
% - Classes that constitute the power system model inherit from PowerSystemModel.
% - Classes intended for analysis assistance inherit from auxiliary.
%
% See also auxiliary, LayerPackage

    properties (Dependent, SetAccess=private) % Parameters
        % [Hz] Nominal frequency of the network the model belongs to.
        % net.tab_parameter.base.Hz; GUILDA.config("Model","Hz") when not attached to a
        % network. This is the omega0 passed to the model functions (models multiply it by 2*pi).
        % <@Type> double
        r_Hz
    end
    methods
        function Hz = get.r_Hz(obj)
            Hz = obj.get_Hz();
        end
    end
end
