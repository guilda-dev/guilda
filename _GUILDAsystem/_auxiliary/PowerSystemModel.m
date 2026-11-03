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

    methods
        function Hz = get_Hz(obj)
            % Nominal frequency [Hz] of the network the model belongs to.
            % net.tab_parameter.base.Hz; GUILDA.config("Model","Hz") when not attached to a
            % network. This is the omega0 passed to the model functions (models multiply it by 2*pi).
            arguments (Output)
                Hz (1,1) double % [Hz] Nominal frequency.
            end
            p = obj;
            while isa(p,"PowerSystemModel") && ~isa(p,"PowerNetwork")
                p = p.parent;
            end
            if isa(p,"PowerNetwork")
                Hz = p.para_base.Hz;
            else
                Hz = GUILDA.config("Model","Hz");
            end
        end
    end
end
