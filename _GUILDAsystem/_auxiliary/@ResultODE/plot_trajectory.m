function G = plot_trajectory(obj, opt)
% Plot a trajectory of the buses or components.
%
% Draws a trajectory against time [s]: for the buses, the voltage magnitude (Vabs), the
% voltage angle (Vangle) or the power P / Q injected by the components; for the
% components, a state, an input or an output given by its name (e.g. omega, Pmech), with
% one line per component of the selected buses that has it: the columns of
% get_trajectory(Quantity, Bus=Bus). By default it draws Vabs of every bus.
% The only figure of the analysis: simulate draws none (its PlotFcn is a live display
% during the simulation).
%
% It returns the chart G (GraphChart): one line per bus, tagged with the bus tag, or per
% component, tagged with the full component tag. The panel is a time panel: G.set_time(t)
% draws a cursor at t, and G.link(G2) with the graph of plot_spring_model or plot_diagram
% of the same result moves the cursor with its animation.
%
% <@Examples>
% ```matlab
% G = res.plot_trajectory(Quantity="omega");
% G.set_style(G.tab_element.Tag(1), Color="r", LineWidth=2);
% S = res.plot_spring_model();
% G.link(S);
% S.animate();                 % the cursor of G follows
% ```
%
% See also ResultODE.get_trajectory, GraphChart, ResultODE.plot_spring_model, ResultODE.plot_diagram
    arguments (Input)
        obj
        opt.Quantity (1,1) string = "Vabs"  % "Vabs", "Vangle", "P", "Q", or a state, input or output name of the components.
        opt.Bus      {mustBeText} = "all"   % Tags of the buses to draw (for a component quantity: the buses of the components); "all" for every bus.
        opt.Parent = []                     % Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure.
    end
    arguments (Output)
        G  % The chart (GraphChart), one line per bus or component.
    end
    tab = obj.get_trajectory(opt.Quantity, Bus=opt.Bus);     % the same columns as get_trajectory
    Y = tab{:, 2:end};
    sv_tag = reshape(string(tab.Properties.VariableNames(2:end)), [], 1);
    sv_label = dictionary(["Vabs", "Vangle", "P", "Q"], ["|V| [pu]", "\angle V [rad]", "P [pu]", "Q [pu]"]);
    s_label = opt.Quantity;
    if isKey(sv_label, s_label)
        s_label = sv_label(s_label);
    end

    s_title = "Time response";
    if obj.flag == 0
        s_title = s_title + " - stopped by TimeLimit";
    elseif ~obj.l_success
        s_title = s_title + " - stopped by the solver";
    end
    rv_t = reshape(tab.t, 1, []);
    sct = struct();
    sct.rv_t       = rv_t;
    sct.sct_panel  = struct("s_title", s_title, "s_xlabel", "t [s]", "s_ylabel", s_label, "l_time", true);
    sct.sct_series = struct("rv_x", rv_t, "rm_y", Y, "sv_tag", sv_tag, "r_lineWidth", 1.2);
    G = GraphChart(sct, Parent=opt.Parent);
end
