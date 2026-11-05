function ax = Plot(obj, opt)
% Plot a trajectory of the buses or components.
%
% Draws a trajectory against time [s]: for the buses, the voltage magnitude (Vabs), the
% voltage angle (Vangle) or the power P / Q injected by the components; for the
% components, a state or an input given by its name (e.g. omega, Pmech), with one line
% per component of the selected buses that has it. By default it draws Vabs of every bus.
% simulate(..., Plot=true) calls it.
    arguments
        obj
        opt.Quantity (1,1) string = "Vabs" % "Vabs", "Vangle", "P", "Q", or a state or input name of the components.
        opt.Bus      {mustBeText} = "all" % Tags of the buses to draw (for a component quantity: the buses of the components); "all" for every bus.
        opt.Parent = [] % Container to draw in. A new figure when empty.
    end
    arguments (Output)
        ax % Axes holding the trajectories.
    end
    sv_plot = string(opt.Bus);
    if isequal(sv_plot, "all")
        sv_plot = obj.sv_bus;
    end
    [lv_found, iv_bus] = ismember(sv_plot, obj.sv_bus);
    if ~all(lv_found)
        error(msg("GUILDA:ResultODE:UnknownBus", char(join(sv_plot(~lv_found), ", "))));
    end

    r = obj.odeResults;
    [Y, sv_legend, s_label] = trajectory(r, obj.sv_bus, obj.c_component, iv_bus, opt.Quantity);
    if width(Y) == 0
        error(msg("GUILDA:ResultODE:UnknownQuantity", char(opt.Quantity)));
    end
    if isempty(opt.Parent)
        opt.Parent = figure();
    end

    ax = axes(opt.Parent);
    plot(ax, r.t, Y, "LineWidth", 1.2);
    xlabel(ax, "t [s]");
    ylabel(ax, s_label);
    legend(ax, sv_legend, "Location", "best", "Interpreter", "none");
    grid(ax, "on");
    s_title = "Time response";
    if obj.flag == 0
        s_title = s_title + " - stopped by TimeLimit";
    elseif ~obj.l_success
        s_title = s_title + " - stopped by the solver";
    end
    title(ax, s_title);
end


function [Y, sv_legend, s_label] = trajectory(r, sv_tag, c_component, iv_bus, s_q)
% Columns to draw and their legend entries
    Y = zeros(numel(r.t), 0);
    sv_legend = strings(1,0);
    switch s_q
        case "Vabs"
            s_label = "|V| [pu]";
            for i = iv_bus(:)'
                Y(:,end+1) = abs(r.Bus(i).V{:,:} * [1;1j]); %#ok<AGROW>
            end
        case "Vangle"
            s_label = "\angle V [rad]";
            for i = iv_bus(:)'
                Y(:,end+1) = angle(r.Bus(i).V{:,:} * [1;1j]); %#ok<AGROW>
            end
        case {"P","Q"}
            s_label = s_q + " [pu]";
            for i = iv_bus(:)'
                Y(:,end+1) = r.Bus(i).PQ.(s_q); %#ok<AGROW>
            end
        otherwise
            s_label = s_q;
            for i = iv_bus(:)'
                for j = 1:numel(r.Bus(i).Component)
                    for s_part = ["X","U"]
                        if ~isfield(r.Bus(i).Component(j), s_part)    % a bus without components
                            continue
                        end
                        tab = r.Bus(i).Component(j).(s_part);
                        if width(tab) > 0 && any(string(tab.Properties.VariableNames) == s_q)
                            Y(:,end+1) = tab.(s_q);                  %#ok<AGROW>
                            sv_legend(end+1) = c_component{i}(j);      %#ok<AGROW>
                        end
                    end
                end
            end
            return
    end
    sv_legend = reshape(sv_tag(iv_bus), 1, []);
end
