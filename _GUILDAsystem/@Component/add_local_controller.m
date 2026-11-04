function add_local_controller(obj, varargin)
% Attach local controllers (AVR, PSS, governor, LQR, ...) to the component, in the order given.
%
% The key of a controller says where it goes:
%
% - "avr": attached to the component (the PSS feeds it)
% - "pss": attached to the AVR of the component
% - "local": attached to the component in the place of an AVR (e.g. controller.local_LQR)
% - "governor": attached to the component beside the AVR or "local" controller (it
%   drives Pmech, e.g. controller.governor.IEEJ_LPT1)
%
% A component has two slots for top-level controllers: the AVR or "local" controller
% (with the PSS under an AVR), then the governor. a_LocalController lists them in this
% order whatever the order of attachment, and so do the variables (get_variable_map).
% A controller reads the outputs and states of the component it observes by the names
% of its inputs sv_u ("Xall" / "Yall": all the states / all the outputs), and its outputs
% drive the inputs of the component of the same name (an input event or a global
% controller on such an input adds to them).
% A new AVR or "local" controller replaces the attached one. The PSS of an old AVR moves
% to a new AVR unless a PSS is given in the same call, and is detached when the new
% controller is not an AVR. A new PSS replaces the attached one, and a new governor the
% attached governor. Replaced controllers are detached (they no longer refer to this
% component).
% The two top-level controllers must drive different inputs: a governor and an AVR or
% "local" controller with a common output (e.g. a local_LQR on all the inputs, Pmech
% among them) are rejected with an error.
% A controller still attached elsewhere is rejected with an error: each component needs
% its own controller object.
% A key other than "avr", "pss", "local" or "governor" is rejected with an error, and so
% is an output that matches no input of the component (for a PSS, of its AVR), e.g. an
% AVR on a load.
% A misspelled input is not an error, because it has the same form as an input left
% unconnected on purpose.
% Each addition is logged as a "Topology" edit, so the equilibrium becomes stale.
%
% <@Examples>
% ```matlab
% gen = net.a_Bus{1}.a_Component{1};
% gen.add_local_controller(controller.avr.AVR_ST1("avr1"));
% gen.add_local_controller(controller.avr.AVR_ST1("avr1"), controller.pss.PSS1("pss1"));
% gen.add_local_controller(controller.governor.IEEJ_LPT1("gov1", PLM=5));
% ```
%
% See also Component.remove_local_controller, LocalController, controller.avr.AVR_ST1, controller.pss.PSS1, controller.governor.IEEJ_LPT1, controller.local_LQR
    arguments
        obj
    end
    arguments (Input,Repeating)
        varargin (1,1) {mustBeA(varargin, 'LocalController')}   % Local controllers with key "avr", "pss", "local" or "governor", e.g. an AVR followed by a PSS.
    end

    l_givenPss = any(cellfun(@(con) con.key == "pss", varargin));

    % Checked before anything changes, so a rejected call leaves the component as it was
    cellfun(@check_key, varargin);
    cellfun(@(con) check_parent(con, obj), varargin);
    check_outputs(obj, varargin);

    for idx = 1:numel(varargin)
        new_con = varargin{idx};
        switch new_con.key
            case {"avr", "local"}
                old_avr = chain_of(obj);
                if isempty(old_avr)
                    set_slots(obj, new_con, governor_of(obj));
                    new_con.set_parent(obj)    % so that AVR parameter edits reach the edit log
                    obj.log_edit(obj.str_tag+" <<-Add--- "+new_con.str_tag, "Topology");
                else
                    warning(msg("GUILDA:Component:ReplaceController", label(new_con), char(new_con.str_tag), char(old_avr.str_tag), char(obj.str_tag)))
                    a_pss = old_avr.a_LocalController;
                    old_avr.remove_local_controller();
                    old_avr.set_parent([])
                    set_slots(obj, new_con, governor_of(obj));
                    new_con.set_parent(obj)
                    if ~isempty(a_pss)
                        if l_givenPss || new_con.key ~= "avr"
                            a_pss{1}.set_parent([])
                        else
                            new_con.add_local_controller(a_pss{1})
                            a_pss{1}.set_parent(new_con)
                        end
                    end
                    obj.log_edit(obj.str_tag+" <<-replace--- "+new_con.str_tag+" (was "+old_avr.str_tag+")", "Topology");
                end

            case "governor"
                old_gov = governor_of(obj);
                set_slots(obj, chain_of(obj), new_con);
                if isempty(old_gov)
                    obj.log_edit(obj.str_tag+" <<-Add--- "+new_con.str_tag, "Topology");
                else
                    if old_gov ~= new_con
                        warning(msg("GUILDA:Component:ReplaceController", label(new_con), char(new_con.str_tag), char(old_gov.str_tag), char(obj.str_tag)))
                        old_gov.set_parent([])
                    end
                    obj.log_edit(obj.str_tag+" <<-replace--- "+new_con.str_tag+" (was "+old_gov.str_tag+")", "Topology");
                end
                new_con.set_parent(obj)

            case "pss"
                avr = chain_of(obj);
                if isempty(avr)
                    error(msg("GUILDA:Component:NotExtAvr"))
                end
                if avr.key ~= "avr"
                    error(msg("GUILDA:Component:PssParentKey", char(new_con.str_tag), char(avr.str_tag), char(avr.key), char(obj.str_tag)))
                end
                if isempty(avr.a_LocalController)
                    obj.log_edit(obj.str_tag+" <<-Add--- "+new_con.str_tag, "Topology");
                else
                    old_pss = avr.a_LocalController{1};
                    if old_pss ~= new_con
                        warning(msg("GUILDA:Component:ReplaceController", "PSS", char(new_con.str_tag), char(old_pss.str_tag), char(avr.str_tag)))
                        old_pss.set_parent([])
                    end
                    obj.log_edit(obj.str_tag+" <<-replace--- "+new_con.str_tag+" (was "+old_pss.str_tag+")", "Topology");
                end
                avr.add_local_controller(new_con)
                new_con.set_parent(avr)
        end
    end

    obj.l_hasController = ~isempty(obj.a_LocalController);
end

function con = chain_of(comp)
    % The AVR or "local" controller of the component ([] if none)
    con = slot_of(comp, ["avr", "local"]);
end

function con = governor_of(comp)
    % The governor of the component ([] if none)
    con = slot_of(comp, "governor");
end

function con = slot_of(comp, sv_key)
    con = [];
    for k = 1:numel(comp.a_LocalController)
        if ismember(comp.a_LocalController{k}.key, sv_key)
            con = comp.a_LocalController{k};
            return
        end
    end
end

function set_slots(comp, chain, gov)
    % The top-level controllers in their fixed order: the AVR or "local" controller, then the governor
    a_con = cell(0,1);
    if ~isempty(chain)
        a_con = [a_con; {chain}];
    end
    if ~isempty(gov)
        a_con = [a_con; {gov}];
    end
    comp.a_LocalController = a_con;
end

function check_parent(con, comp)
    % A controller has one parent: its parent must be none, or already on this component
    % (the component itself, or for a PSS the AVR of the component)
    parent = con.a_Component;
    if isempty(parent)
        return
    end
    if con.key == "pss"
        avr = chain_of(comp);
        l_same = ~isempty(avr) && parent == avr;
    else
        l_same = parent == comp;
    end
    if ~l_same
        error(msg("GUILDA:Component:SharedController", label(con), char(con.str_tag), char(parent.str_tag), char(comp.str_tag)))
    end
end

function check_key(con)
    if ~ismember(con.key, ["avr", "pss", "local", "governor"])
        error(msg("GUILDA:Component:InvalidControllerKey", char(con.str_tag), char(con.key)))
    end
end

function check_outputs(comp, a_con)
    % Follow the call in order, so that a PSS is checked against the AVR it will go under.
    % A PSS without an AVR is left to the NotExtAvr error of the attachment.
    % The two top-level controllers after the call must drive different inputs.
    chain    = chain_of(comp);
    gov      = governor_of(comp);
    sv_chain = outputs_of(chain, comp);
    sv_gov   = outputs_of(gov, comp);
    for idx = 1:numel(a_con)
        con = a_con{idx};
        switch con.key
            case "pss"
                if ~isempty(chain) && chain.key == "avr"
                    check_output(con, con.sv_y, chain);
                end
            case "governor"
                gov    = con;
                sv_gov = outputs_of(con, comp);
                check_output(con, sv_gov, comp);
            otherwise
                chain    = con;
                sv_chain = outputs_of(con, comp);
                check_output(con, sv_chain, comp);
        end
    end
    sv_common = intersect(sv_chain, sv_gov, "stable");
    if ~isempty(sv_common)
        error(msg("GUILDA:Component:ControllerOutputOverlap", char(gov.str_tag), char(chain.str_tag), ...
                  strjoin(cellstr(sv_common(:)'), ', '), char(comp.str_tag)))
    end
end

function sv = outputs_of(con, comp)
    % The inputs of comp that a top-level controller drives once attached to it
    if isempty(con)
        sv = strings(0,1);
    else
        sv = reshape(string(con.driven_inputs(comp)), [], 1);
    end
end

function check_output(con, sv_y, target)
    % target: the object whose inputs sv_u the outputs sv_y of the controller replace
    sv_miss = setdiff(string(sv_y), string(target.sv_u), "stable");
    if ~isempty(sv_miss)
        error(msg("GUILDA:Component:ControllerOutput", strjoin(cellstr(sv_miss(:)'), ', '), char(con.str_tag), ...
                  char(target.str_tag), strjoin(cellstr(string(target.sv_u(:)')), ', ')))
    end
end

function str = label(con)
    % Name of the controller kind in the ReplaceController and SharedController messages
    switch con.key
        case "avr"
            str = "AVR";
        case "pss"
            str = "PSS";
        case "governor"
            str = "Governor";
        otherwise
            str = "Local controller";
    end
end
