function add_local_controller(obj, varargin)
% Attach local controllers (AVR, PSS) to the component, in the order given.
%
% The AVR is attached to the component and the PSS to the AVR (the PSS feeds the AVR).
% A new AVR replaces the attached one, and the PSS of the old AVR moves to the new AVR
% unless a PSS is given in the same call. A new PSS replaces the attached one.
% Replaced controllers are detached (they no longer refer to this component).
% Each addition is logged as a "Topology" edit, so the equilibrium becomes stale.
%
% <@Examples>
% ```matlab
% gen = net.a_Bus{1}.a_Component{1};
% gen.add_local_controller(controller.avr.AVR_ST1("avr1"));
% gen.add_local_controller(controller.avr.AVR_ST1("avr1"), controller.pss.PSS1("pss1"));
% ```
%
% See also LocalController, controller.avr.AVR_ST1, controller.pss.PSS1
    arguments
        obj
    end
    arguments (Input,Repeating)
        varargin (1,1) {mustBeA(varargin, 'LocalController')}   % Local controllers: an AVR, a PSS, or an AVR followed by a PSS.
    end

    l_givenPss = any(cellfun(@(con) con.key == "pss", varargin));

    for idx = 1:numel(varargin)
        new_con = varargin{idx};
        switch new_con.key
            case "avr"
                if isempty(obj.a_LocalController)
                    obj.a_LocalController = {new_con};
                    new_con.set_parent(obj)    % so that AVR parameter edits reach the edit log
                    obj.log_edit(obj.str_tag+" <<-Add--- "+new_con.str_tag, "Topology");
                else
                    old_avr = obj.a_LocalController{1};
                    warning('GUILDA:Component:ReplaceController', '%s', ...
                            msg('GUILDA:Component:ReplaceController', "AVR", char(new_con.str_tag), char(old_avr.str_tag), char(obj.str_tag)))
                    a_pss = old_avr.a_LocalController;
                    old_avr.remove_local_controller();
                    old_avr.set_parent([])
                    obj.a_LocalController = {new_con};
                    new_con.set_parent(obj)
                    if ~isempty(a_pss)
                        if l_givenPss
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
