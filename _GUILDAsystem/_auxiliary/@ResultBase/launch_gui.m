function h = launch_gui(obj, h_container, opt)
% Show the result in a GUI: header, the plot_, disp_, get_ and export methods as buttons, and a view area.
%
% With no container it opens a new uifigure; with a container (uifigure, uipanel, uitab or
% uigridlayout) it fills it, so that the GUI can be embedded in another app. The buttons
% are the methods of the result in functionSignatures.json, grouped as Plot, Display, Get
% and Export, so a result class needs no GUI code. A method with options asks for them in
% a dialog (DrawerOptionDialog.ask); plots are drawn in the plot panel, and the text of
% disp_* and the values of get_* are shown in the text area. See DrawerResultGUI.
%
% Every action runs as a line of MATLAB code in History (HistoryGUILDA.run) on the result
% variable Variable of its workspace (set to this result when the workspace has no such
% variable): the code is logged, and `h.history.get_script()` returns a script that repeats
% the actions, drawing the plots in new figures. The default history prints each `>> code`
% in the Command Window; its script needs the result in the workspace as Variable.
%
% <@Examples>
% ```matlab
% res = network.IEEE9bus().calculate_powerflow();
% h = res.launch_gui();                        % new window
% fig = uifigure();
% h = res.launch_gui(uipanel(uigridlayout(fig, [1 1])));   % embedded in a panel
% hist = HistoryGUILDA();
% hist.run("Power flow", "Calculate", "net = network.IEEE9bus(); res_pf = net.calculate_powerflow();");
% h = hist.get_variable("res_pf").launch_gui(History=hist, Variable="res_pf");
% hist.get_script()                            % the power flow and the actions of the GUI
% ```
%
% See also DrawerResultGUI, HistoryGUILDA, DrawerOptionDialog
    arguments (Input)
        obj
        h_container = []                                    % Container to fill: uifigure, uipanel, uitab or uigridlayout (default: a new uifigure).
        opt.History (1,1) HistoryGUILDA                     % Log that runs and records the actions (default: a new HistoryGUILDA(Echo=true)).
        opt.Variable (1,1) string {mustBeValidVariableName} = "res"  % Name of the result in the workspace of History.
    end
    arguments (Output)
        h DrawerResultGUI  % The GUI.
    end
    if ~isfield(opt, "History")
        opt.History = HistoryGUILDA(Echo=true, Header=["Actions of the result GUI of " + class(obj) + ".", ...
            "Run it with the result in the workspace as " + opt.Variable + "."]);
    end
    try
        value = opt.History.get_variable(opt.Variable);
    catch    % no such variable: the result is set
        value = obj;
        opt.History.set_variable(opt.Variable, obj);
    end
    if ~(isa(value, "ResultBase") && isscalar(value) && value == obj)
        error(msg("GUILDA:ResultBase:OtherVariable", opt.Variable, class(value)))
    end
    h = DrawerResultGUI(obj, h_container, opt.History, opt.Variable);
end
