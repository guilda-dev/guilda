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
% Edit handling (the edit log itself is LayerPackage's):
%
% - The cached f_* function handles are rebuilt at the start of every analysis:
%   check_edit calls the hook apply_edit("odefcn") on every layer of the subtree. Only
%   Component, LocalController and GlobalController own handles and override it; a call
%   of the model functions without an analysis since an edit uses the previous handles.
% - edit_effect maps the tag of an edit to what it makes stale (the handles, the
%   equilibrium). Whether the equilibrium is stale is read from the edit log of the
%   network (PowerNetwork.l_staleEquilibrium).
%
% See also auxiliary, LayerPackage

    methods(Access=protected)
        flag = check_edit(obj)
        apply_edit(obj, s_target)
        [lv_odefcn, lv_equilibrium] = edit_effect(obj, sv_tag, sv_log)
    end

    methods
        Hz = get_Hz(obj)
    end
end
