function ax = Plot(obj, opt)
% <@Desc>
% Draws a trajectory against time [s]: for the buses, the voltage magnitude (Vabs), the
% voltage angle (Vangle) or the power P / Q injected by the components; for the
% components, a state or an input given by its name (e.g. omega, Pmech), with one line
% per component of the selected buses that has it. By default it draws Vabs of every bus.
% simulate(..., Plot=true) calls it.
% <@Role> Plot
% <@Summary> Plot a trajectory of the buses or components.
% <@Signatures>
% [
%   "Plot(result)",
%   "ax = Plot(result, Quantity=str, Bus=sv_bus, Parent=container)"
% ]
% <@Parameters>
% [
%   {"Name": "result", "Type": "odeSimulationResult", "Description": "Result to plot.", "Required": true, "Default": "-"},
%   {"Name": "Quantity", "Type": "string scalar", "Description": "\"Vabs\", \"Vangle\", \"P\", \"Q\", or a state or input name of the components.", "Required": false, "Default": "\"Vabs\""},
%   {"Name": "Bus", "Type": "string", "Description": "Tags of the buses to draw (for a component quantity: the buses of the components); \"all\" for every bus.", "Required": false, "Default": "\"all\""},
%   {"Name": "Parent", "Type": "figure, panel or tab", "Description": "Container to draw in. A new figure when empty.", "Required": false, "Default": "[]"}
% ]
% <@Returns>
% [
%   {"Name": "ax", "Type": "matlab.graphics.axis.Axes", "Description": "Axes holding the trajectories."}
% ]
    arguments
        obj
        opt.Quantity (1,1) string = "Vabs"
        opt.Bus      {mustBeText} = "all"
        opt.Parent = []
    end
    sv_plot = string(opt.Bus);
    if isequal(sv_plot, "all")
        sv_plot = obj.sv_bus;
    end
    [lv_found, iv_bus] = ismember(sv_plot, obj.sv_bus);
    if ~all(lv_found)
        error('GUILDA:odeSimulationResult:UnknownBus', '%s', ...
              msg('GUILDA:odeSimulationResult:UnknownBus', char(join(sv_plot(~lv_found), ", "))));
    end

    r = obj.odeResults;
    [Y, sv_legend, str_label] = trajectory(r, obj.sv_bus, obj.c_component, iv_bus, opt.Quantity);
    if isempty(Y)
        error('GUILDA:odeSimulationResult:UnknownQuantity', '%s', ...
              msg('GUILDA:odeSimulationResult:UnknownQuantity', char(opt.Quantity)));
    end
    if isempty(opt.Parent)
        opt.Parent = figure();
    end

    ax = axes(opt.Parent);
    plot(ax, r.t, Y, "LineWidth", 1.2);
    xlabel(ax, "t [s]");
    ylabel(ax, str_label);
    legend(ax, sv_legend, "Location", "best", "Interpreter", "none");
    grid(ax, "on");
    str_title = "Time response";
    if obj.flag == 0
        str_title = str_title + " - stopped by TimeLimit";
    elseif ~obj.l_success
        str_title = str_title + " - stopped by the solver";
    end
    title(ax, str_title);
end


function [Y, sv_legend, str_label] = trajectory(r, sv_tag, c_component, iv_bus, str_q)
% Columns to draw and their legend entries
    Y = zeros(numel(r.t), 0);
    sv_legend = strings(1,0);
    switch str_q
        case "Vabs"
            str_label = "|V| [pu]";
            for i = iv_bus(:)'
                Y(:,end+1) = abs(r.Bus(i).V{:,:} * [1;1j]); %#ok<AGROW>
            end
        case "Vangle"
            str_label = "\angle V [rad]";
            for i = iv_bus(:)'
                Y(:,end+1) = angle(r.Bus(i).V{:,:} * [1;1j]); %#ok<AGROW>
            end
        case {"P","Q"}
            str_label = str_q + " [pu]";
            for i = iv_bus(:)'
                Y(:,end+1) = r.Bus(i).PQ.(str_q); %#ok<AGROW>
            end
        otherwise
            str_label = str_q;
            for i = iv_bus(:)'
                for j = 1:numel(r.Bus(i).Component)
                    for str_part = ["X","U"]
                        if ~isfield(r.Bus(i).Component(j), str_part)    % a bus without components
                            continue
                        end
                        tab = r.Bus(i).Component(j).(str_part);
                        if ~isempty(tab) && any(string(tab.Properties.VariableNames) == str_q)
                            Y(:,end+1) = tab.(str_q);                  %#ok<AGROW>
                            sv_legend(end+1) = c_component{i}(j);      %#ok<AGROW>
                        end
                    end
                end
            end
            return
    end
    sv_legend = reshape(sv_tag(iv_bus), 1, []);
end
