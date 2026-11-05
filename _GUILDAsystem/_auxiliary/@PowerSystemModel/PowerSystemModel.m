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
        function set_odefcn(obj)
        % Build the f_* handle cache from the current parameters and network frequency.
        % Layers that own handles (Component, LocalController, GlobalController)
        % override this; other layers have nothing to build.
            arguments (Input)
                obj
            end
            obj.s_odefcn = "updated";
        end

        function mark_odefcn(obj)
        % Mark the built handles of the layer and its descendants as "editted", for a change
        % of the frequency they read: a network Hz edit (PowerNetwork.handle_edit) and an
        % attach (Component.set_bus, LocalController.set_parent, GlobalController.set_parent).
        % check_edit builds them at the next analysis. Handles never built stay "unset".
            arguments (Input)
                obj
            end
            if obj.s_odefcn == "updated"
                obj.s_odefcn = "editted";
            end
            for a = reshape(obj.children, 1, [])
                if isa(a{1}, "PowerSystemModel")
                    a{1}.mark_odefcn();
                end
            end
        end

        function flag = check_edit(obj)
        % Build the handles that are not up to date and report whether initialize has run.
        %
        % Calls set_odefcn on every layer of the subtree whose s_odefcn is not "updated"
        % ("unset": never built; "editted": a dynamics edit, a network Hz edit or an attach
        % since the last build), parent before children. Called at the start of every
        % analysis that uses the f_* handles: initialize, calculate_continuation_powerflow
        % and, through PowerNetwork.require_equilibrium, solver_ODE.solve and
        % solver_LIN.solve (net.simulate, net.linearize, net.get_sys); the get_sys of each
        % layer; LocalController.validate; and Component.get_dx_algebraic and
        % LocalController.get_dx_algebraic when the layer itself is not "updated" (a direct
        % call; in a simulation the solver has already checked every layer). See
        % PowerNetwork.check_edit.
            arguments (Input)
                obj
            end
            arguments (Output)
                flag % True when initialize has run; on PowerNetwork, also nothing that changes the equilibrium was edited since.
            end
            if obj.s_odefcn ~= "updated"
                obj.set_odefcn();
            end
            for a = reshape(obj.children, 1, [])
                if isa(a{1}, "PowerSystemModel")
                    a{1}.check_edit();
                end
            end
            flag = obj.l_initialized;
        end

        function handle_edit(obj, a_layer, tag, log)
        % An edit of one of the layer's own Parameter containers that makes the handles
        % stale marks them "editted" (when they were "updated"). log_edit calls this on
        % every layer from the edited layer up to the top.
            arguments (Input)
                obj            % Layer on the path from the edited layer to the top.
                a_layer        % Edited layer (a Parameter container for a parameter edit).
                tag string     % Kind of edit (see edit_effect).
                log string     % Log message.
            end
            if obj.s_odefcn == "updated" && isa(a_layer, "Parameter") && obj.is_parent_of(a_layer)
                if obj.edit_effect(tag, log)
                    obj.s_odefcn = "editted";
                end
            end
        end

        function [lv_odefcn, lv_equilibrium] = edit_effect(obj, sv_tag, sv_log) %#ok<INUSL>
        % What each edit-log row makes stale, from its tag and log (one edit in handle_edit,
        % the rows of the network in PowerNetwork.l_staleEquilibrium, check_edit and
        % initialize).
        %   tag                    f_* handles   equilibrium
        %   Parameter(dynamics)    stale         stale
        %   Parameter(base)        -             stale     (PowerNetwork para_base: baseMVA;
        %                                                   no model handle holds it)
        %   Parameter(base), Hz    -             -         (log "edit Hz": PowerNetwork.handle_edit
        %                                                   marks the handles of every layer; the
        %                                                   equilibrium does not depend on the
        %                                                   nominal frequency)
        %   Parameter(powerflow)   -             stale
        %   Topology               -             stale     (add_/remove_/replace_)
        %   Slack                  -             stale
        %   Initialize             -             stale     (initialize is writing the equilibrium;
        %                                                   the row is cleared when it finishes)
        %   Parameter(operation)   -             -
        %   Parameter(OPF)         -             -
        %   Parameter(graph)       -             -
        %   OPF                    -             -         (set_opffcn / reset_opffcn)
        %   Tag                    -             -         (rename through s_tag)
            arguments (Input)
                obj            % Any layer (the mapping does not depend on it).
                sv_tag string  % Tags of the rows (Nx1).
                sv_log string  % Log messages of the rows (Nx1).
            end
            arguments (Output)
                lv_odefcn      % True for rows that make the handles of the parameter's owner stale (Nx1).
                lv_equilibrium % True for rows that make the equilibrium stale (Nx1).
            end
            lv_odefcn      = sv_tag == "Parameter(dynamics)";
            lv_equilibrium = matches(sv_tag, ["Parameter(dynamics)", "Parameter(powerflow)", "Topology", "Slack", "Initialize"]) ...
                           | (sv_tag == "Parameter(base)" & sv_log ~= "edit Hz");
        end
    end

    methods
        function Hz = get_Hz(obj)
            % Nominal frequency [Hz] of the network the model belongs to.
            % net.tab_parameter.base.Hz; GUILDA.config("Model","Hz") when not attached to a
            % network. This is the omega0 passed to the model functions (models multiply it by 2*pi).
            arguments (Input)
                obj
            end
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
