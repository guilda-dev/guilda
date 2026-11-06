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
% What is out of date is kept by each layer (LayerPackage: `sct_stale`); only
% PowerNetwork.initialize brings it up to date. get_Hz gives every model the nominal
% frequency of its network.
%
% See also auxiliary, LayerPackage

    methods
        Hz = get_Hz(obj)
    end
end
