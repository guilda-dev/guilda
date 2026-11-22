classdef DrawerResultGUI < auxiliary
% GUI of an analysis result: header, the methods of the result as buttons, and a view area.
%
% ResultBase.launch_gui creates one, in a new uifigure or in a given container (uifigure,
% uipanel, uitab or uigridlayout), so that it can be embedded in another app.
%
% - Header (logo blue band over a lime line): the variable of the result, its class, the
%   success state (l_success), a Docs button that opens the class reference
%   (GUILDA.doc("class", ...)), the toggle "Display options" and a summary line (network,
%   solver, flag, elapsed time).
% - Method list: the methods of the result in the two functionSignatures.json files
%   (`_GUILDAsystem/resources` and `_GUILDAsystem/_auxiliary/resources`; entries
%   "<class>.<method>" of the class and of its superclasses) with the prefixes plot_, disp_
%   and get_ and the method export, as buttons in the groups Plot, Display, Get and Export.
%   A button shows a readable label (plot_voltage: "Voltage", get_lmp: "LMP", export:
%   "Export to file") and the method in its tooltip. The list comes from the files only, so
%   a result class needs no GUI code.
% - View area: the tabs Plot (a panel the plot_* methods draw in), Text (the text of the
%   disp_* methods, the values of the get_* methods and the file of export) and Log (the
%   log of the history, HistoryGUILDA.attach_view, drawn when the tab is first opened).
% - Default view on open, not logged (it changes no variable of the history): the Text tab
%   shows the summary (disp_summary, or the display of the result) and the Plot tab the
%   first plot_* method of the list with its defaults.
% - While "Display options" is pressed, the control panel of the last plot that returned a
%   GraphBase (G.show_controls) stands right of the plot panel. Its changes only set
%   properties of the graph and are not logged: they change no variable, and the script
%   draws the plots with their defaults.
% - A plot that animates starts playing once it is drawn in a visible window, as if its
%   Play button had been pressed (autoplay; never under matlab -batch or in a hidden
%   window): the first output graph of the call with a playback bar gets G.play(), so one
%   timer plays (ResultODE.plot_diagram: G plays and its linked side chart G_chart
%   follows; ResultOPF.plot_iteration: G_net plays and G_chart follows). A chart whose time
%   only moves a cursor has no bar and does not play (plot_trajectory). This holds for the
%   first plot of the default view too. It does not block the window, and stops when the
%   window closes, when another plot replaces it, or with Pause of the playback bar.
%   Network diagrams run their flow animation (FlowAnimation). The control panel of
%   "Display options" belongs to the first graph output (for [G, G_chart]: G).
%
% A button runs its method as a line of MATLAB code through the history (HistoryGUILDA.run),
% on the result variable of its workspace. A method with options first asks for them
% (DrawerOptionDialog.ask; Parent and the file of export are not asked); a method without
% options runs at once. The code is what the log and the script show:
%
% - plot_*: `G = res.plot_voltage(Quantity="angle", Parent=h_parent);` with the outputs named
%   as in the signature (`[G_chart, G_net] = res.plot_iteration(Parent=h_parent);`). Before
%   each run the GUI sets h_parent of the workspace to its plot panel and clears the panel.
%   The history gets the entry `h_parent = [];` once, before the first plot of any result
%   GUI, so the exported script draws every plot in a new figure.
% - disp_*: `s_text = res.disp_bus(Unit="SI");` and `disp(s_text)`; the Text tab shows
%   s_text without hyperlinks.
% - get_*: `tab = res.get_lmp();`; the Text tab shows each output.
% - export: `s_file = res.export("<path>", Table="branch");`. The path comes from uiputfile
%   when the figure is visible, otherwise it is a file of tempdir (no user can answer).
%
% A failed run stays in the log (not in the script); the Text tab shows its message, and an
% alert too when the figure is visible. The colors are the fixed light palette of the
% GUILDA GUIs (tools.gui_palette).
%
% <@Examples>
% ```matlab
% res = network.IEEE9bus().calculate_powerflow();
% h = res.launch_gui();            % new window, with HistoryGUILDA(Echo=true)
% h.history.get_script()           % the code of the buttons pressed
% ```
%
% See also ResultBase.launch_gui, HistoryGUILDA, DrawerOptionDialog, DrawerModelGUI

    properties(SetAccess = private) % Display
        a_target     % Result shown. <@Type> ResultBase
        history      % Log that runs and records the actions. <@Type> HistoryGUILDA
    end
    properties(Access = private) % Layout
        h_container  % Container the GUI fills (uifigure, uipanel, uitab or uigridlayout). <@Type> matlab.ui.container
        s_variable   % Name of the result in the workspace of the history. <@Type> string
        h_plot       % Panel the plot_* methods draw in. <@Type> matlab.ui.container.Panel
        h_text       % Text area of the disp_* and get_* outputs. <@Type> matlab.ui.control.TextArea
        h_tabs       % Tab group of the view area. <@Type> matlab.ui.container.TabGroup
        G_plot       % Graph of the last plot ([] when it returned none). <@Type> GraphBase
    end

    methods
        function obj = DrawerResultGUI(a_target, h_container, history, s_variable)
        % Create the GUI of a result in a container (a new uifigure when empty).
            arguments (Input)
                a_target (1,1) ResultBase                          % Result to show.
                h_container                                        % uifigure, uipanel, uitab or uigridlayout; [] opens a new uifigure.
                history (1,1) HistoryGUILDA                        % Log that runs the actions; its workspace holds the result as s_variable.
                s_variable (1,1) string {mustBeValidVariableName}  % Name of the result in the workspace of the history.
            end
            arguments (Output)
                obj  % The GUI.
            end
            if isempty(h_container)
                h_container = uifigure("Name", class(a_target) + " " + s_variable, ...
                    "Color", tools.gui_palette().rv_background, "Position", [100 100 1100 680]);
                if isprop(h_container, "Theme")
                    h_container.Theme = "light";
                end
            elseif ~tools.is_ui_container(h_container)
                error(msg("GUILDA:DrawerResultGUI:NotUIContainer", class(h_container)))
            end
            obj.a_target    = a_target;
            obj.history     = history;
            obj.s_variable  = s_variable;
            obj.h_container = h_container;
            obj.render();
        end
    end

    methods(Access = private)
        render(obj)
        run_method(obj, s_signature)
        show_plot_controls(obj)
        show_log(obj, h_tab)
        autoplay(obj, c_output)
    end
end
