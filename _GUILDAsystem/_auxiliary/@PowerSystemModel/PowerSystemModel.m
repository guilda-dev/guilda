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
% - `s_odefcn` is the state of the cached f_* function handles built by set_odefcn:
%   "unset" (never built), "editted" (built, but no longer matching the parameters or the
%   network frequency) or "updated" (built from the current values). An edit of a
%   "dynamics" parameter of the layer (handle_edit), a network Hz edit
%   (PowerNetwork.handle_edit, on every layer of the network) and an attach
%   (Component.set_bus, LocalController.set_parent, GlobalController.set_parent, on the
%   attached subtree; mark_odefcn) turn "updated" into "editted"; set_odefcn sets
%   "updated". The handles are built when they are used: check_edit, at the start of an
%   analysis, calls set_odefcn on every layer that is not "updated". Only Component,
%   LocalController and GlobalController own handles. Its GetAccess is public (Hidden)
%   because the DebugScript tests, which are scripts, read it.
% - edit_effect maps the tag of an edit to what it makes stale (the handles, the
%   equilibrium). Whether the equilibrium is stale is read from the edit log of the
%   network (PowerNetwork.l_staleEquilibrium).
%
% See also auxiliary, LayerPackage

    properties(SetAccess=protected, Hidden) % Edit handling
        s_odefcn (1,1) string {mustBeMember(s_odefcn,["unset","editted","updated"])} = "unset"  % State of the f_* handle cache: "unset", "editted" or "updated" (see the class help).
    end

    methods(Access=protected)
        set_odefcn(obj)
        mark_odefcn(obj)
        flag = check_edit(obj)
        handle_edit(obj, a_layer, tag, log)
        [lv_odefcn, lv_equilibrium] = edit_effect(obj, sv_tag, sv_log)
    end

    methods
        Hz = get_Hz(obj)
    end
end
