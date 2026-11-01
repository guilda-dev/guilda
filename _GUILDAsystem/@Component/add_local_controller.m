function add_local_controller(obj, varargin)
% Attach local controllers (AVR, PSS, LQR, ...) to the component, in the order given.
%
% The key of a controller says where it goes:
%
% - "avr": attached to the component (the PSS feeds it)
% - "pss": attached to the AVR of the component
% - "local": attached to the component in the place of an AVR (e.g. controller.local_LQR)
%
% A controller reads the outputs and states of the component it observes by the names
% of its inputs sv_u ("Xall" / "Yall": all the states / all the outputs), and its outputs
% replace the inputs of the component of the same name.
% A new AVR or "local" controller replaces the attached one. The PSS of an old AVR moves
% to a new AVR unless a PSS is given in the same call, and is detached when the new
% controller is not an AVR. A new PSS replaces the attached one.
% Replaced controllers are detached (they no longer refer to this component).
% A controller still attached elsewhere is rejected with an error: each component needs
% its own controller object.
% A key other than "avr", "pss" or "local" is rejected with an error, and so is an output
% that matches no input of the component (for a PSS, of its AVR), e.g. an AVR on a load.
% A misspelled input is not an error, because it has the same form as an input left
% unconnected on purpose.
% Each addition is logged as a "Topology" edit, so the equilibrium becomes stale.
%
% <@Examples>
% ```matlab
% gen = net.a_Bus{1}.a_Component{1};
% gen.add_local_controller(controller.avr.AVR_ST1("avr1"));
% gen.add_local_controller(controller.avr.AVR_ST1("avr1"), controller.pss.PSS1("pss1"));
% ```
%
% See also LocalController, controller.avr.AVR_ST1, controller.pss.PSS1, controller.local_LQR
    arguments
        obj
    end
    arguments (Input,Repeating)
        varargin (1,1) {mustBeA(varargin, 'LocalController')}   % Local controllers with key "avr", "pss" or "local", e.g. an AVR followed by a PSS.
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
                if isempty(obj.a_LocalController)
                    obj.a_LocalController = {new_con};
                    new_con.set_parent(obj)    % so that AVR parameter edits reach the edit log
                    obj.log_edit(obj.str_tag+" <<-Add--- "+new_con.str_tag, "Topology");
                else
                    old_avr = obj.a_LocalController{1};
                    warning('GUILDA:Component:ReplaceController', '%s', ...
                            msg('GUILDA:Component:ReplaceController', label(new_con), char(new_con.str_tag), char(old_avr.str_tag), char(obj.str_tag)))
                    a_pss = old_avr.a_LocalController;
                    old_avr.remove_local_controller();
                    old_avr.set_parent([])
                    obj.a_LocalController = {new_con};
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

            case "pss"
                if isempty(obj.a_LocalController)
                    error(msg('GUILDA:Component:NotExtAvr'))
                end
                avr = obj.a_LocalController{1};
                if avr.key ~= "avr"
                    error(msg('GUILDA:Component:NotExtAvr'))
                end
                if isempty(avr.a_LocalController)
                    obj.log_edit(obj.str_tag+" <<-Add--- "+new_con.str_tag, "Topology");
                else
                    old_pss = avr.a_LocalController{1};
                    if old_pss ~= new_con
                        warning('GUILDA:Component:ReplaceController', '%s', ...
                                msg('GUILDA:Component:ReplaceController', "PSS", char(new_con.str_tag), char(old_pss.str_tag), char(avr.str_tag)))
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

function check_parent(con, comp)
    % A controller has one parent: its parent must be none, or already on this component
    % (the component itself, or for a PSS the AVR of the component)
    parent = con.a_Component;
    if isempty(parent)
        return
    end
    if con.key == "pss"
        l_same = ~isempty(comp.a_LocalController) && parent == comp.a_LocalController{1};
    else
        l_same = parent == comp;
    end
    if ~l_same
        error('GUILDA:Component:SharedController', '%s', ...
              msg('GUILDA:Component:SharedController', label(con), char(con.str_tag), char(parent.str_tag), char(comp.str_tag)))
    end
end

function check_key(con)
    if ~ismember(con.key, ["avr", "pss", "local"])
        error('GUILDA:Component:InvalidControllerKey', '%s', ...
              msg('GUILDA:Component:InvalidControllerKey', char(con.str_tag), char(con.key)))
    end
end

function check_outputs(comp, a_con)
    % Follow the call in order, so that a PSS is checked against the AVR it will go under.
    % A PSS without an AVR is left to the NotExtAvr error of the attachment.
    if isempty(comp.a_LocalController)
        upper = [];
    else
        upper = comp.a_LocalController{1};
    end
    for idx = 1:numel(a_con)
        con = a_con{idx};
        if con.key ~= "pss"
            check_output(con, comp);
            upper = con;
        elseif ~isempty(upper) && upper.key == "avr"
            check_output(con, upper);
        end
    end
end

function check_output(con, target)
    % target: the object whose inputs sv_u the outputs of the controller replace
    sv_miss = setdiff(string(con.sv_y), string(target.sv_u), "stable");
    if ~isempty(sv_miss)
        error('GUILDA:Component:ControllerOutput', '%s', ...
              msg('GUILDA:Component:ControllerOutput', strjoin(cellstr(sv_miss(:)'), ', '), char(con.str_tag), ...
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
        otherwise
            str = "Local controller";
    end
end
